function [clsfr]=train_nf_clsfr(trlen_ms,nfParams,varargin)
% configure a simple neuro-feedback classifier/pipeline
% 
% [clsfr]=train_nf_clsfr(trlen_ms,nfParams,....);
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
% Options:  (specify as 'name',value pairs, e.g. train_ersp_clsfr(X,Y,'fs',10);
%  ch_names  - {str} cell array of strings which label each channel
%  ch_pos    - [3 x nCh] 3-d co-ordinates of the data electrodes
%              OR
%              {str} cell array of strings which label each channel in *1010 system*
%  capFile   - 'filename' file from which to load the channel position information.
%              *this overrides* ch_pos if given
%  overridechnms - [bool] flag if channel order from 'capFile' overrides that from the 'ch_names' option
%  fs        - sampling rate of the data
%  timeband  - [2 x 1] band of times to use for classification, all if empty ([])
%  freqband  - [2 x 1] or [3 x 1] or [4 x 1] band of frequencies to use
%              EMPTY for *NO* spectral filter
%              OR
%              { nFreq x 1 } cell array of discrete frequencies to pick
%  width_ms  - [float] width in millisecs for the windows in the welch spectrum (250)
%              estimation.  
%              N.B. the output frequency resolution = 1000/width_ms, so 4Hz with 250ms
%  spatialfilter -- [str] one of 'slap','car','none','csp','ssep'              ('slap')
%  badchrm   - [bool] do we do bad channel removal    (1)
%  badchthresh - [float] threshold in std-dev units to id channel as bad (3.5)
%  badtrrm   - [bool] do we do bad trial removal      (1)
%  badtrthresh - [float] threshold in std-dev units to id trial as bad (3)
%  detrend   - [int] do we detrend/center the data          (1)
%              0 - do nothing
%              1 - detrend the data
%              2 - center the data (i.e. subtract the mean)
%  verb      - [int] verbosity level
%  class_names - {str} names for each of the classes in Y in *increasing* order ([])
% Outputs:
%  clsfr  - [struct] structure contining the stuff necessary to apply the trained classifier
%           |.w      -- [size(X) x nSp] weighting over X (for each subProblem)
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
opts=struct('classify',1,'fs',[],'timeband',[],'freqband',[],...
            'width_ms',250,'width_samp',[],'windowType','hanning','aveType','amp',...
            'downsample',[],'detrend',1,'spatialfilter','car',...
            'badchrm',1,'badchthresh',3.1,'badchscale',2,...
            'badtrrm',1,'badtrthresh',3,'badtrscale',2,...
            'ch_pos',[],'ch_names',[],'verb',0,'capFile','1010','overridechnms',0,...
            'visualize',2,'badCh',[],'nFold',10,'class_names',[],'zeroLab',1,'trlen_samp',[]);
[opts,varargin]=parseOpts(opts,varargin);

di=[]; ch_pos=opts.ch_pos; ch_names=opts.ch_names;
if ( iscell(ch_pos) && ischar(ch_pos{1}) ) ch_names=ch_pos; ch_pos=[]; end;
% convert names to positions
if ( isempty(ch_pos) && ~isempty(opts.capFile) && (~isempty(ch_names) || opts.overridechnms) ) 
  di = addPosInfo(ch_names,opts.capFile,opts.overridechnms); % get 3d-coords
  if ( any([di.extra.iseeg]) ) 
    ch_pos=cat(2,di.extra.pos3d); ch_names=di.vals; % extract pos and channels names    
  else % fall back on showing all data
    warning('Capfile didnt match any data channels -- no EEG?');
    ch_pos=[];
  end
end
fs=opts.fs; if ( isempty(fs) ) warning('No sampling rate specified... assuming fs=250'); fs=250; end;

% convert from time in _ms to time in samples
if ( isempty(trlen_ms) )
  trlen_samp=opts.trlen_samp;
else
  trlen_samp=round(trlen_ms/1000 * fs);
end

%2) Bad channel identification & removal
isbadch=[]; chthresh=[];
if ( opts.badchrm || ~isempty(opts.badCh) )
  isbadch = false(numel(ch_names),1);
  if ( ~isempty(ch_pos) ) isbadch(numel(ch_pos)+1:end)=true; end;
  if ( ~isempty(opts.badCh) )
    isbadch(opts.badCh)=true;
  end
end    

%2.2) time range selection
timeIdx=[];
if ( ~isempty(opts.timeband) ) warning('Time band selection not supported!'); end

%3) Spatial filter/re-reference
R=[];
if ( numel(ch_names)> 5 ) % only spatial filter if enough channels
  sftype=lower(opts.spatialfilter);
  switch ( sftype )
   case 'slap';
    fprintf('3) Slap\n');
    if ( ~isempty(ch_pos) )       
      R=sphericalSplineInterpolate(ch_pos,ch_pos,[],[],'slap');%pre-compute the SLAP filter we'll use
    else
      warning('Cant compute SLAP without channel positions!'); 
    end
   case 'car';     R=eye(numel(ch_names))-(1./numel(ch_names));
   case 'none';
   otherwise; warning(sprintf('Unrecog/unsupported spatial filter type: %s. Ignored!',opts.spatialfilter ));
  end
end

%3.5) Bad trial removal
isbadtr=[]; trthresh=[];
if ( opts.badtrrm )  warning('Bad-trial-remove : Not supported'); end

%4) welch to convert to power spectral density
[X,wopts,winFn]=welchpsd(zeros(1,trlen_samp),2,...
								 'width_ms',opts.width_ms,'width_samp',opts.width_samp,...
								 'windowType',opts.windowType,'fs',fs,...
                         'aveType',opts.aveType,'detrend',1);
width_samp = wopts.width_samp; width_ms=wopts.width_ms;
if ( isempty(width_ms) ) width_ms = width_samp * 1000 / fs; end;
freqs=0:(1000/width_ms):fs/2; % position of the frequency bins

%5) sub-select the range of frequencies we care about
fIdx=[];
if ( ~isempty(opts.freqband) && size(X,2)>10 && ~isempty(fs) ) 
  fprintf('5) Select frequencies\n');
  if ( isnumeric(opts.freqband) )
    if ( numel(opts.freqband)>2 ) % convert the diff band spects to upper/lower frequencies
      if ( numel(opts.freqband)==3 ) opts.freqband=opts.freqband([1 3]);
      elseif(numel(opts.freqband)==4 ) opts.freqband=[mean(opts.freqband([1 2])) mean(opts.freqband([3 4]))];
      end
    end
    [ans,fIdx(1)]=min(abs(freqs-max(freqs(1),opts.freqband(1)))); % lower frequency bin
    [ans,fIdx(2)]=min(abs(freqs-min(freqs(end),opts.freqband(2)))); % upper frequency bin
    fIdx = int32(fIdx(1):fIdx(2));
  elseif ( iscell(opts.freqband) ) %set of discrete-frequencies to pick
    freqband=[opts.freqband{:}]; % convert to vector
    freqband=[freqband;2*freqband];%3*freqband]; % select higher harmonics also
    fIdx=false(size(X,2),1);
    for fi=1:numel(freqband);
      [ans,tmp]=min(abs(freqs-freqband(fi))); % lower frequency bin
      fIdx(tmp)=true;
    end    
  end
  freqs=freqs(fIdx);
end;

%6) configure classifier(s)
W=zeros(numel(ch_names),numel(freqs),numel(nfParams)); 
b=zeros(1,numel(nfParams));
for ci=1:numel(nfParams)  
  parmsci=nfParams(ci);
  % get the weighting over channels
  chWght = zeros(numel(ch_names),1);
  if ( isempty(parmsci.electrodes) ) chWght(:)=1; 
  elseif ( numel(parmsci.electrodes)==numel(ch_names) && isnumeric(parmsci.electrodes))
    chWght=parmsci.electrodes;
  elseif ( iscell(parmsci.electrodes) || ischar(parmsci.electrodes) || isnumeric(parmsci.electrodes) )
    if ( ischar(parmsci.electrodes) ) parmsci.electrodes={parmsci.electrodes}; end;
    for ei=1:numel(parmsci.electrodes);
      if(iscell(parmsci.electrodes)) chei=parmsci.electrodes{ei}; else chei=parmsci.electrodes(ei); end
      if( isnumeric(chei) ) % index of the channel to weight
        chWght(abs(chei))=sign(chei);
      elseif ( ischar(chei) )
        val=1; if ( isequal('-',chei(1)) ) val=-1; chei=chei(2:end); end;
        cheiIdx = strcmpi(chei,ch_names);
        if ( ~any(cheiIdx) ) warning('Couldnt find a channel name match for : %s\n',chei); end;
        chWght(cheiIdx)=val;
      end
    end
  end
  % averge positive/negative weight over channels
  if ( any(chWght>0) ) chWght(chWght>0) = chWght(chWght>0) ./ sum(abs(chWght(chWght>0)));  end;
  if ( any(chWght<0) ) chWght(chWght<0) = chWght(chWght<0) ./ sum(abs(chWght(chWght<0)));  end;
  if ( sum(abs(chWght))>0 ) chWght = chWght./sum(abs(chWght)); end;
  
  % get the weighting over frequencies
  freqWght = zeros(numel(freqs),1);
  if( numel(parmsci.freqband)>4 ) % direct weighting over frequencies
    freqWght(1:min(end,numel(parmsci.freqband)))=parmsci.freqband(1:min(end,numel(freqs)));
  elseif ( numel(parmsci.freqband)==2 )  % start,stop frequencies
    [ans,tmpfIdx(1)]=min(abs(freqs-max(freqs(1)  ,parmsci.freqband(1)))); % lower frequency bin
    [ans,tmpfIdx(2)]=min(abs(freqs-min(freqs(end),parmsci.freqband(2)))); % upper frequency bin
    freqWght(tmpfIdx(1):tmpfIdx(2))=1;
    if ( sum(abs(freqWght))>0 ) freqWght=freqWght./sum(abs(freqWght));  end % average over frequencies
  elseif ( isempty(parmsci.freqband) ) % ave over all frequencies if not given
      freqWght(:)=1;
  end

  % make the combined weighting
  W(:,:,ci) = chWght * freqWght' ;
    
end;


clsfr.W=W;
clsfr.b=b;
clsfr.dim=3;
clsfr.spMx=[];
clsfr.spKey=[];
clsfr.spDesc={nfParams.label}; % label for each output
clsfr.binsp=1;

%7) combine all the info needed to apply this pipeline to testing data
clsfr.type        = 'ERsP';
clsfr.fs          = fs;   % sample rate of training data
clsfr.detrend     = opts.detrend; % detrend?
clsfr.isbad       = isbadch;% bad channels to be removed
clsfr.spatialfilt = R;    % spatial filter used for surface laplacian

clsfr.filt        = []; % DUMMY -- so ERP and ERSP classifier have same structure fields
clsfr.outsz       = []; % DUMMY -- so ERP and ERSP classifier have same structure fields
clsfr.timeIdx     = timeIdx; % time range to apply the classifer to

clsfr.windowFn    = winFn;% temporal window prior to fft
clsfr.welchAveType= opts.aveType;% other options to pass to the welchpsd
clsfr.freqIdx     = fIdx; % start/end index of frequencies to keep

clsfr.badtrthresh = []; 
clsfr.badchthresh = []; 
clsfr.dvstats     = [];
return;
%------------------------------------------
function testCase()
feedback = struct('label','alphaL',...
                  'freqband',[8 12],...
                  'electrodes',{{'FP2'}}); % don't forget double cell for struct
capFile = 'muse';
overridechnms=1;
clsfr = buffer_train_nf_clsfr(1000,feedback,hdr,'spatialfilter','none','capFile',capFile,'overridechnms',overridechnms);
