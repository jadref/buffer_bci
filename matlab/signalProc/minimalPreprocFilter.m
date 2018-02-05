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
issingle=isa(x,'single');

                                % spatial-filter
if( ~isempty(state.R) )
  if( isnumeric(state.R) )
     x = state.R*reshape(x,size(x,1),[]);
  elseif( strcmpi(state.R,'robust') ) % median CAR
     mu = median(x,1);
     x  = x - repmat(mu,[size(x,1),1]);
  end
end

                                % channel selection
if( ~isempty(state.chseln) )
   x=x(state.chseln,:,:);
end

                                % spectral-filter
if( ~isempty(state.B) )
   % use double for internal filter processing, IIR filter is very very sensitive to precision used...
  if(issingle)   x=double(x); end;
  [x,state.spectfiltstate]=filter(state.B,state.A,x,state.spectfiltstate,2);
  if( issingle ) x=single(x); end;
end
                                % artifact removal
if( ~isempty(state.artfiltstate) )
   ox=x;
   [x,state.artfiltstate]=artChRegress(x,state.artfiltstate);
   %mad(ox,x)
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


function [state]=initState(x,varargin)
  % parse the configuration options and initialize the filter state
  state=struct('chseln',[],'R',[],'artfiltstate',[],'B',[],'A',[],'spectfiltstate',[],'subsampleStep',[],'hdr',[]);
                                % argument processing
  opts=struct('chseln',[],'capFile',[],'overridechnms',0,'spatialFilter','car','artifactCh',[],'subsample',[],'bands',[.5 30],'spectfilttype',[],...
              'hdr',[],'fs',[],'ch_names','','ch_pos',[],'verb',0);
  opts=parseOpts(opts,varargin);

                                % parameter setup
  hdr=opts.hdr;
  fs=opts.fs;
  if(isempty(fs) && ~isempty(opts.hdr) )
     if(isfield(opts.hdr,'fSample')) fs=opts.hdr.fSample;
     elseif(isfield(opts.hdr,'Fs'))  fs=opts.hdr.Fs;
     end;
  end
  ch_names=opts.ch_names; if( isempty(ch_names) && ~isempty(opts.hdr) ) ch_names=opts.hdr.label; end;
  iseeg=[]; 
  if( ~isempty(opts.capFile) ) % additionally only pick channels which match capfile names     
     di = addPosInfo(ch_names,opts.capFile,opts.overridechnms); % get 3d-coords
     ch_names(1:numel(di.vals)) = di.vals; % update channel names
     iseeg=[di.extra.iseeg];
  end
  issingle=isa(x,'single');

                                % spatial filter
  if( ~isempty(opts.spatialFilter) )
    R=[];
                                % make the fixed spatial filter matrix
    if( any(strcmpi(opts.spatialFilter,{'robust','robustcar'})) )
       R = 'robust';
    elseif(strcmpi(opts.spatialFilter,'car'))
       wght=zeros(size(x,1),1); if(~isempty(iseeg)) wght(iseeg)=1; end;
       R = eye(size(x,1)) - repmat(wght'./sum(wght),[size(x,1) 1]);
    elseif( iscell(opts.spatialFilter) ) % set channel names to use as average reference
       wght=zeros(size(x,1),1);
       for ci=1:numel(ch_names);
          if( any(strcmpi(ch_names{ci},opts.spatialFilter)) ) 
             fprintf('SpatialFilter: Matched %s\n',ch_names{ci});
             wght(ci)=1; 
          end;
       end
       R = eye(size(x,1)) - repmat(wght'./sum(wght),[size(x,1) 1]);
    elseif( isnumeric(opts.spatialFilter) && size(opts.spatialFilter,2)==1 ) % set channel numbers to use as average reference
       wght=zeros(size(x,1),1); wght(opts.spatialFilter)=1;
       % WARNING: watch the transpose.....
       R= eye(size(x,1)) - repmat(wght'./sum(wght),[size(x,1) 1]);
    else
      warning('spatial filter type not supported yet');
    end
    state.R=R;
    % apply
    if( isnumeric(state.R) )
       x = state.R*reshape(x,size(x,1),[]);
    elseif( strcmpi(state.R,'robust') ) % median CAR
       mu = median(x,1);
       x  = x - repmat(mu,[size(x,1),1]);
    end    
  end

                                % channel selection
  chseln=opts.chseln;
  if( ~isempty(chseln) )
     if ( isnumeric(chseln) && any(chseln>1) ) % get logical indicator of keeping channels
        tmp=chseln; chseln=false(size(x,1),1); chseln(tmp)=true; 
     elseif( iscell(chseln) )
        tmp=chseln; chseln=false(size(x,1),1); 
        for ci=1:numel(ch_names);
           if( any(strcmpi(ch_names{ci},tmp)) ) 
              chseln(ci)=true; 
           end;
        end
     elseif( strcmp(chseln,'eegonly') && ~isempty(iseeg) && any(iseeg) )
        chseln = false(size(x,1),1); 
        chseln(iseeg)=true;
     end
  end; 
  state.chseln=chseln;
  if( ~isempty(state.chseln) ) % apply the selection
     fprintf('ChannelSeln:'); fprintf('%s,',ch_names{chseln});fprintf('\n');
     x=x(state.chseln,:,:);
  end

  
                                % spectral fitler
  if( ~isempty(opts.bands) )
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
    % pre-warm the filter state, reduce startup artifacts
    if( issingle ) x=double(x); end;
    [ans,state.spectfiltstate]=filter(state.B,state.A,repmat(mean(x,2),[1,size(x,2)]),[],2);
    % apply
    x = filter(state.B,state.A,x,state.spectfiltstate,2);
    if( issingle ) x=single(x); end;
  end

  % eog removal
  if( ~isempty(opts.artifactCh) ) 
     % N.B. needs to be fast enough to respond to transient artifacts, like eye-blinks...
     artHalfLife_s = .5; 
     artHalfLife_samp = artHalfLife_s* fs; 
     artBands      = [.1 30];%[.2 inf];
     % initialize and apply
     [x,artfiltstate]=artChRegress(x,[],[1 2 3],opts.artifactCh,'ch_names',ch_names,'fs',fs,'bands',artBands,'center',0,'covFilt',artHalfLife_samp);
     state.artfiltstate = artfiltstate;
  end
  
                                % re-sample
  ofs=fs;
  if( ~isempty(opts.subsample) )
    subsampleratio = ceil(fs/opts.subsample);    
    if( subsampleratio>1 ) % only if needed
       ofs=fs/subsampleratio;
       fprintf('Subsampling: %g -> %g hz\n',fs,ofs);
       state.subsampleStep = subsampleratio;
    end
  end

  % update the hdr info
  if(isempty(hdr)) hdr=struct('fs',ofs,'label',ch_names,'iseeg',iseeg);
  else 
     hdr.fs=ofs; 
     if(isfield(opts.hdr,'fSample')) fs=opts.hdr.fSample;
     elseif(isfield(opts.hdr,'Fs'))  fs=opts.hdr.Fs;
     end;
     hdr.label=ch_names;
  end
  state.hdr=hdr;