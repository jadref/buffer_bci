function [clsfr,res,X,Y]=buffer_train_clsfr(X,Y,hdr,varargin);
% train ERSP (frequency-domain) classifier with ft-buffer based data/events input
%
%   [clsfr,res,X,Y]=buffer_train_clsfr(X,Y,hdr,varargin);
%
% Inputs:
%  X -- [ch x time x epoch] data
%       OR
%       [struct epoch x 1] where the struct contains a buf field of buffer data
%       OR
%       {[float ch x time] epoch x 1} cell array of data
%  Y -- [epoch x 1] set of labels for the data epochs
%       OR
%       [struct epoch x 1] set of buf event structures which contain epoch labels in value field
%  hdr-- [struct] buffer header structure
% Options:
%  trainFn -- [str/function_handle] the function to call to do the actual classifier training. ([])
%              This should have the signature:
%              [clsfr,res,X,Y] = trainFn(X,Y,....)
%             And accept as a minumum the name,value options: ch_names, ch_pos, fs, badCh
%  capFile -- [str] name of file which contains the electrode position info  ('1010')
%  overridechnms -- [bool] does capfile override names from the header    (false)
%  varargin -- all other options are passed as option arguments to train_ersp_clsfr, e.g.
%              freqband,timeband,spatialfilter,badchrm,badtrrm,detrend,etc..
% Outputs:
%  clsfr   -- [struct] a classifer structure
%           |.W      -- [size(X) x nSp] weighting over X (for each subProblem)
%           |.b      -- [nSp x 1] bias term
%           |.dim    -- [ind] dimensions of X which contain the trails
%           |.spMx   -- [nSp x nClass] mapping between sub-problems and input classes
%           |.spKey  -- [nClass] label for each class in the spMx, thus:
%                        spKey(spMx(1,:)>0) gives positive class labels for subproblem 1
%           |.spDesc -- {nSp} set of strings describing the sub-problem, e.g. 'lh v rh'
%           |.binsp  -- [bool] flag if this is treated as a set of independent binary sub-problems
%           |.fs     -- [float] sample rate of training data
%           |.detrend -- [bool] detrend the data
%           |.isbad   -- [bool nCh x 1] flag for channels detected as bad and to be removed
%           |.spatialfilt [nCh x nCh] spatial filter used
%           |.filt    -- [float] filter weights for spectral filtering (ERP only)
%           |.outsz   -- [float] info on size after spectral filter for downsampling
%           |.timeIdx -- [2x1] time range (start/end sample) to apply the classifer to
%           |.windowFn -- [float] window used in frequency domain transformation (ERsP only)
%           |.welchAveType -- [str] type of averaging used in frequency domain transformation (ERsP only)
%           |.freqIdx     -- [2x1] range of frequency to keep  (ERsP only)
%  res     -- [struct] a results structure
%  X       -- [ppch x pptime x ppepoch] pre-processed data (N.B. may/will have different size to input X)
%  Y       -- [ppepoch x 1] pre-processed labels (N.B. will have diff num examples to input!)
%
% See Also: train_ersp_clsfr
opts=struct('trainFn',[],'capFile','1010','overridechnms',0);
[opts,varargin]=parseOpts(opts,varargin);
if ( nargin<3 ) error('Insufficient arguments'); end;
% extract the data - from field begining with trainingData
if ( iscell(X) ) 
  if ( isnumeric(X{1}) ) 
    X=cat(3,X{:});
  elseif ( isstruct(X{1}) && isfield(X{1},'buf') )
	 X=cat(1,X{:});
	 X=cat(3,X.buf);
  else
    error('Unrecognised data format!');
  end
elseif ( isstruct(X) )
  X=cat(3,X.buf);
end 
X=single(X);
if ( isstruct(Y) ) % convert event struct into labels
  if ( isnumeric(Y(1).value) ) Y=cat(1,Y.value); 
  elseif(ischar(Y(1).value) )   Y=cat(1,{Y.value}); Y=Y(:);
  else error('Dont know how to handle Y value type');
  end
end; 

fs=[]; chNames={};
if ( isstruct(hdr) )
  if ( isfield(hdr,'channel_names') ) chNames=hdr.channel_names; 
  elseif( isfield(hdr,'label') )      chNames=hdr.label;
  end;
  if ( isfield(hdr,'fsample') )       fs=hdr.fsample; 
  elseif ( isfield(hdr,'Fs') )        fs=hdr.Fs;
  elseif( isfield(hdr,'SampleRate') ) fs=hdr.SampleRate; 
  else warning('Couldnt find sample rate in header, using 100'); fs=100;
  end;
elseif ( iscell(hdr) && ischar(hdr{1}) )
  chNames=hdr;
end
if ( isempty(chNames) ) 
  warning('No channel names set');
  chNames={}; for di=1:size(X,1); chNames{di}=sprintf('%d',di); end;
end
    
% get position info and identify the eeg channels
di = addPosInfo(chNames,opts.capFile,opts.overridechnms); % get 3d-coords
iseeg=false(size(X,1),1); iseeg([di.extra.iseeg])=true;
if ( any(iseeg) ) 
  ch_pos=cat(2,di.extra.pos3d); ch_names=di.vals; % extract pos and channels names    
else % fall back on showing all data
  warning('Capfile didnt match any data channels -- no EEG?');
  ch_names=di.vals; ch_pos  =[]; iseeg(:)=true;
end

% call the actual function which does the classifier training
if ( isempty(opts.trainFn) )
  error('Must specify the training function you wish to use!: e.g. train_erp_clsfr, train_ersp_clsfr, train_ersp_feedback_clsfr, etc..');
end

% ERP classifier
if ( strcmp('erp',opts.trainFn) || strcmp('train_erp_clsfr',opts.trainFn) )
  [clsfr,res,X,Y]=train_erp_clsfr(X,Y,'ch_names',ch_names,'ch_pos',ch_pos,'fs',fs,'badCh',~iseeg,varargin{:});

% ERsP classifier
elseif ( strcmp('ersp',opts.trainFn) || strcmp('train_ersp_clsfr',opts.trainFn)  )
  [clsfr,res,X,Y]=train_ersp_clsfr(X,Y,'ch_names',ch_names,'ch_pos',ch_pos,'fs',fs,'badCh',~iseeg,varargin{:});

% Other: assume given a function to call
else
  [clsfr,res,X,Y]=feval(opts.trainFn,X,Y,'ch_names',ch_names,'ch_pos',ch_pos,'fs',fs,'badCh',~iseeg,varargin{:});
end
return;
