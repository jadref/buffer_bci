function [x,state]=minimalPreprocFilter(x,state,varargin)  
% filter functio to apply minimil (band-pass,car,subsample) pre-processing to raw input data.
%
% Options:
%  bands - [2x1] pass band for spectral filter
%  chSeln - [size(x,1),1] subset of channels to keep
%  spatialFitler - 'str', spatial filter to apply
%  subsample - [1x1] desired output sample rate.  N.B. closest integer re-sample used!
  
                                % setup the state from the options
if( isempty(state) ) 
  state=initState(x,varargin);
end
issing=isa(x,'single');

                                % channel selection
if( ~isempty(state.chseln) )
   x=x(state.chseln,:,:);
end
                                % spectral-filter
if( ~isempty(state.B) )
   % use double for internal filter processing, IIR filter is very very sensitive to precision used...
  if(issing)   x=double(x); end;
  [x,state.spectfiltstate]=filter(state.B,state.A,x,state.spectfiltstate,2);
  if( issing ) x=single(x); end;
end
                                % spatial-filter
if( ~isempty(state.R) )
  if( isnumeric(state.R) )
     x = state.R*reshape(x,size(x,1),[]);
  elseif( isequal(state.R,'robustCAR') ) % median CAR
     mu= median(x,1);
     x = x - repmat(mu,[size(x,1),1]);
  end
end
                                % downsample
if( ~isempty(state.subsampleStep) ) % averaging downsampler, to reduce aliasing effects
  nsubsamp = floor(size(x,2)/state.subsampleStep);
  if( nsubsamp*state.subsampleStep < size(x,2) ) % need to pad
     x = cat(2,x,repmat(x(:,end,:),[1,(nsubsamp+1)*state.subsampleStep-size(x,2),1]));
  end;
  x = mean(reshape(x,[size(x,1),state.subsampleStep,nsubsamp,size(x,3)]),2); % average samples
  x = reshape(x,[size(x,1),size(x,3),size(x,4)]); % remove averaged dim
end


return


function state=initState(x,varargin)
  % parse the configuration options and initialize the filter state
  state=struct('chseln',[],'R',[],'B',[],'A',[],'spectfiltstate',[],'subsampleStep',[]);
                                % argument processing
  opts=struct('chseln',[],'capFile',[],'overridechnms',0,'spatialFilter','car','subsample',[],'bands',[.5 30],'spectfilttype',[],...
              'hdr',[],'fs',[],'ch_names','','ch_pos',[],'verb',0);
  opts=parseOpts(opts,varargin);

                                % parameter setup

                                % channel selection
  chseln=opts.chseln;
  if( ~isempty(chseln) && isnumeric(chseln) && any(chseln>1) ) % get logical indicator of keeping channels
     tmp=chseln; chseln=false(size(x,1),1); chseln(tmp)=true; 
  end; 
  if( ~isempty(opts.capFile) ) % additionally only pick channels which match capfile names
     if( isempty(opts.ch_names) && ~isempty(opts.hdr) ) opts.ch_names=opts.hdr.label; end;
     di = addPosInfo(opts.ch_names,opts.capFile,opts.overridechnms); % get 3d-coords
     if( any([di.extra.iseeg]) )
        if( isempty(chseln) ) chseln=true(size(x,1),1); end; % default to include all
        chseln(~[di.extra.iseeg])=false; % remove non-eeg
     end
  end
  state.chseln=chseln;
  if( ~isempty(state.chseln) ) % apply the selection
     x=x(state.chseln,:,:);
  end
  
                                % spatial filter
  if( ~isempty(opts.spatialFilter) )
    R=[];
                                % make the fixed spatial filter matrix
    if(strcmpi(opts.spatialFilter,'car'))
      R = eye(size(x,1)) - ones(size(x,1),size(x,1))/size(x,1);
    elseif( any(strcmpi(opts.spatialFilter,{'robust','robustcar'})) )
      R = 'robust';
    else
      warning('spatial filter type not supported yet');
    end
    state.R=R;
  end
  
                                % spectral fitler
  if( ~isempty(opts.bands) )
    fs=opts.fs;
    if(isempty(fs) && ~isempty(opts.hdr) )
      if(isfield(opts.hdr,'fSample')) fs=opts.hdr.fSample;
      elseif(isfield(opts.hdr,'Fs'))  fs=opts.hdr.Fs;
      end;
    end
    bands=opts.bands;
    type =opts.spectfilttype;
    if( bands(1)==0 )      type='low';  bands=bands(2);  fprintf('low-pass %gHz\n',bands); % low-pass
    elseif( bands(2)>=fs ) type='high'; bands=bands(1);  fprintf('high-pass %gHz\n',bands);% high-pass
    else                                                 fprintf('band-pass [%g-%g]Hz\n',bands);
    end       
    if( isempty(type) )    [B,A]=butter(4,bands*2/fs); % arg, weird bug in octave for pass
    else                   [B,A]=butter(4,bands*2/fs,type);
    end
    state.B=B;
    state.A=A;
  end
  
                                % re-sample
  if( ~isempty(opts.subsample) )
    subsampleratio = ceil(fs/opts.subsample);    
    if( subsampleratio>1 ) % only if needed
       fprintf('Subsampling: %g -> %g hz\n',fs,fs/subsampleratio);
       state.subsampleStep = subsampleratio;
    end
  end

