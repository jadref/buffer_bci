function [clsfr]=buffer_train_nf_clsfr(trlen_ms,nfParams,hdr,varargin);
% train ERSP (frequency-domain) classifier with ft-buffer based data/events input
%
%   clsfr=buffer_train_ersp_clsfr(X,Y,hdr,varargin);
%
% Inputs:
%  trlen_ms  - [int] length of 1 analysis window in milliseconds
%            OR
%              [ ch x time x epoch ] example pieces of analysis data
%  nfParams  - [ struct nCls x 1 ] neurofeedback paramters structure
%            |.freqband = [2x1] specifies the frequency range to use. Output is average over this range
%            |.electrodes = specifies the set of electrodes to use. One of:
%                    [] - empty means average over all electrodes
%                    [nElect x 1] - gives a weighting over electrodes
%                    {'str'} - gives a list of electrode names to sum together
%                       N.B. use -Cz to negate before summing, 
%                           e.g. to feedback on the lateralisation between C3 and C4 use: {'C3' '-C4'}
%  hdr-- [struct] buffer header structure
% Options:
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
%
% See Also: train_ersp_clsfr
opts=struct('capFile','1010','overridechnms',0);
[opts,varargin]=parseOpts(opts,varargin);
if ( nargin<3 ) error('Insufficient arguments'); end;

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
elseif ( iscell(hdr) && isstr(hdr{1}) )
  chNames=hdr;
end
if ( isempty(chNames) ) 
  warning('No channel names set');
  chNames={}; for di=1:size(X,1); chNames{di}=sprintf('%d',di); end;
end
    
% get position info and identify the eeg channels
di = addPosInfo(chNames,opts.capFile,opts.overridechnms); % get 3d-coords
iseeg=false(numel(chNames),1); iseeg([di.extra.iseeg])=true;
if ( any(iseeg) ) 
  ch_pos=cat(2,di.extra.pos3d); ch_names=di.vals; % extract pos and channels names    
else % fall back on showing all data
  warning('Capfile didnt match any data channels -- no EEG?');
  ch_names=di.vals; ch_pos  =[]; iseeg(:)=true;
end

% call the actual function which does the classifier training
[clsfr]=train_nf_clsfr(trlen_ms,nfParams,'ch_names',ch_names,'ch_pos',ch_pos,'fs',fs,'badCh',~iseeg,varargin{:});
return;
%-------------
function testCase()
hdr=buffer('get_hdr',[]);
buffer_train_nf_clsfr(500,struct('label','alpha','freqband',[8 10],'electrodes','Fz'),'hdr',hdr);