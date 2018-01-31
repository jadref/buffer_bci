function [x,state]=minimalPreprocFilter(x,state,varargin)  
% filter functio to apply minimil (band-pass,car,subsample) pre-processing to raw input data.
%
% Options:
%  bands - [2x1] pass band for spectral filter
%  spatialFitler - 'str', spatial filter to apply
%  subsample - [1x1] desired output sample rate.  N.B. closest integer re-sample used!
  
                                % setup the state from the options
if( isempty(state) ) 
  state=initState(x,varargin);
end
                                % spectral-filter
if( ~isempty(state.B) )
  [x,state.spectfiltstate]=filter(state.B,state.A,x,state.spectfiltstate,2);
end
                                % spatial-filter
if( ~isempty(state.R) )
  x = state.R*reshape(x,size(x,1),[]);
end
                                % downsample
if( ~isempty(state.subsampleStep) )
  x = x(:,1:state.subsampleStep:end,:);
end


return


function state=initState(x,varargin)
  % parse the configuration options and initialize the filter state
  state=struct('R',[],'B',[],'A',[],'spectfiltstate',[],'subsampleStep',[]);
                                % argument processing
  opts=struct('spatialFilter','car','subsample',[],'bands',[.5 30],'spectfilttype',[],...
              'hdr',[],'fs',[],'ch_names','','ch_pos',[],'verb',0);
  opts=parseOpts(opts,varargin);

                                % parameter setup
  
                                % spatial filter
  if( ~isempty(opts.spatialFilter) )
    R=[];
                                % make the fixed spatial filter matrix
    if(strcmpi(opts.spatialFilter,'car'))
      R = eye(size(x,1)) - ones(size(x,1),size(x,1))/size(x,1);
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
    if( bands(1)==0 )      type='low';  bands=bands(2); % low-pass
    elseif( bands(2)>=fs ) type='high'; bands=bands(1); % high-pass
    end       
    if( isempty(type) )    [B,A]=butter(5,bands*2/fs); % arg, weird bug in octave for pass
    else                   [B,A]=butter(5,bands*2/fs,type);
    end
    state.B=B;
    state.A=A;
  end
  
                                % re-sample
  if( ~isempty(opts.subsample) )
    subsampleratio = ceil(fs/opts.subsample);
    fprintf('Subsampling: %g -> %g hz\n',fs,fs/subsampleratio);
    state.subsampleStep = subsampleratio;
  end

