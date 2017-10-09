function [clsfr,res,X,Y]=train_spect_clsfr(X,Y,varargin)
% train a simple ERSP (spectral power) classifer
% 
% [clsfr,res,X,Y]=train_ersp_clsfr(X,Y,...)
%
% Inputs:
%  X         - [ ch x time x epoch ] data set
%  Y         - [ nCls x epoch ] set of data class labels
% Options:  (specify as 'name',value pairs, e.g. train_ersp_clsfr(X,Y,'fs',10);
%  ch_names  - {str} cell array of strings which label each channel
%  ch_pos    - [3 x nCh] 3-d co-ordinates of the data electrodes
%              OR
%              {str} cell array of strings which label each channel in *1010 system*
%  capFile   - 'filename' file from which to load the channel position information.
%              *this overrides* ch_pos if given
%  overridechnms - [bool] flag if channel order from 'capFile' overrides that from the 'ch_names' option
%  eegonly   - use the capFile info to specify the eeg subset and only use those channels
%  fs        - sampling rate of the data
%  timeband_ms- [2 x 1] band of times in milliseconds to use for classification, all if empty ([])
%  freqband  - [2 x 1] or [3 x 1] or [4 x 1] band of frequencies to use
%              EMPTY for *NO* spectral filter
%              OR
%              { nFreq x 1 } cell array of discrete frequencies to pick
%  width_ms  - [float] width in millisecs for the windows in the welch spectrum (250)
%              estimation.  
%              N.B. the output frequency resolution = 1000/width_ms, so 4Hz with 250ms
%  step_ms   - [float] time between spectrum computations                              (width_ms/2)
%  timefeat  - [bool] as a raw averaged response per-channel feature?                  (0)
%  spatialfilter -- [str] one of 'slap','car','none','csp','ssep','trwht'              ('slap')
%       WARNING: CSP is particularly prone to *overfitting* so treat any performance estimates with care...
%  adaptspatialfiltFn -- 'fname' or {fname args} function to call for adaptive spatial filtering, such as 'adaptWhitenFilt', or 'artChRegress'
%                fname should be the name of a *filterfunction* to call.  This should have a prototype:
%                 [X,state]=fname(X,state,args{:})
%                where state is some arbitary internal state of the filter which is propogated between calls
%                NOTE: during *training* we call with extra arguments about the channel names and positions as:
%                           [X,state]=fname(X,state,args{:},'ch_names',ch_names,'ch_pos',ch_pos);
%                SEE ALSO: adaptWhitenFilt, artChRegress, rmEMGFilt
%  featFiltFn -- 'fname' or {fname args} function to for feature filtering, (such as normalization, bias-correction etc.)
%                fname should be the name of a *filterfunction* to call.  This should have a prototype:
%                 [X,state]=fname(X,state,args{:})
%                where state is some arbitary internal state of the filter which is propogated between calls
%                SEE ALSO: biasFilt, stdFilt, rbiasFilt
%  badchrm     - [bool] do we do bad channel removal    (1)
%  badchthresh - [float] threshold in std-dev units to id channel as bad (3.5)
%  badchscale  - [float] multiplier for the bad-ch-thresold for on-line bad-channel detection (4)
%  badtrrm     - [bool] do we do bad trial removal      (1)
%  badtrthresh - [float] threshold in std-dev units to id trial as bad (3)
%  badtrscale  - [float] multiplier for the bad trial threshold for on-line bad-trial detectin (4)
%  detrend   - [int] do we detrend/center the data          (1)
%              0 - do nothing
%              1 - detrend the data
%              2 - center the data (i.e. subtract the mean)
%  visualize - [int] visualize the data                     (1)
%               0 - don't visualize
%               1 - visualize, but don't wait
%               2 - visualize, and wait for user before continuing
%  verb      - [int] verbosity level
%  ch_names  - {str} cell array of strings which label each channel
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
%  res    - [struct] detailed results for each fold
%  X       -- [ppch x pptime x ppepoch] pre-processed data (N.B. may/will have different size to input X)
%  Y       -- [ppepoch x 1] pre-processed labels (N.B. will have diff num examples to input!)
opts=struct('classify',1,'fs',[],'timeband_ms',[],'freqband',[],...
            'width_ms',500,'windowType','hamming','aveType',[],'step_ms',[],'timefeat',0,...
            'detrend',1,'spatialfilter','slap',...
            'adaptspatialfiltFn',[],'adaptspatialfiltstate',[],...
            'badchrm',1,'badchthresh',3.1,'badchscale',4,'eegonly',1,...
            'badtrrm',1,'badtrthresh',3,'badtrscale',4,...
				'featFiltFn',[],...
            'ch_pos',[],'ch_names',[],'verb',0,'capFile','1010','overridechnms',0,...
            'visualize',1,'badCh',[],'nFold',10,'class_names',[],'zeroLab',1);
[opts,varargin]=parseOpts(opts,varargin);

% get the sampling rate
if ( isempty(opts.fs) ) error('Sampling rate not specified!'); end;
di=[]; ch_pos  =opts.ch_pos; ch_names=opts.ch_names;
if ( iscell(ch_pos) && ischar(ch_pos{1}) ) ch_names=ch_pos; ch_pos=[]; end;
% convert names to positions
if ( isempty(ch_pos) && ~isempty(opts.capFile) && (~isempty(ch_names) || opts.overridechnms) ) 
  di = addPosInfo(ch_names,opts.capFile,opts.overridechnms); % get 3d-coords
  if ( any([di.extra.iseeg]) ) 
    ch_pos=cat(2,di.extra.pos3d); ch_names=di.vals; % extract pos and channels names
    if( opts.eegonly )% add the non-eeg channels to the set of bad-channels to be removed
      if( isempty(opts.badCh) )
        opts.badCh=~[di.extra.iseeg];
      else
        if ( islogical(opts.badCh) )    opts.badCh = opts.badCh | ~[di.extra.iseeg];
        elseif( isnumeric(opts.badCh) ) opts.badCh = [opts.badCh(:); find(~[di.extra.iseeg])];
        end
      end
    end
  else % fall back on showing all data
    warning('Capfile didnt match any data channels -- no EEG?');
    ch_pos=[];
  end
end
fs=opts.fs; if ( isempty(fs) ) warning('No sampling rate specified... assuming fs=250'); fs=250; end;

%1) Detrend
if ( opts.detrend )
  if ( isequal(opts.detrend,1) )
    fprintf('1) Detrend\n');
    X=detrend(X,2); % detrend over time
  elseif ( isequal(opts.detrend,2) )
    fprintf('1) Center\n');
    X=repop(X,'-',mean(X,2));
  end
end

%2) Bad channel identification & removal
isbadch=[]; chthresh=[];
if ( opts.badchrm || (~isempty(opts.badCh) && sum(opts.badCh)>0) )
  fprintf('2) bad/non-eeg channel removal, ');
  isbadch = false(size(X,1),1);
  % pre-remove non-eeg or pre-specified to ignore channels
  if ( ~isempty(ch_pos) )      isbadch(numel(ch_pos)+1:end)=true;
  end;
  if ( ~isempty(opts.badCh) )  isbadch(opts.badCh(1:min(end,size(isbadch,1))))=true;
  end;
  if( any(isbadch) )   fprintf('(%d noneeg) ',sum(isbadch));  end  

                        % auto-threshold to determine additional bad channels
  if( opts.badchrm ) 
    if( ~any(isbadch) ) % remove using all channels
      [isbadch,chstds,chthresh]=idOutliers(X,1,opts.badchthresh); 
    else % only consider the good subset
      goodCh=find(~isbadch);
      [isbad2,chstds,chthresh]=idOutliers(X(goodCh,:,:),1,opts.badchthresh);
      isbadch(goodCh(isbad2))=true;
    end;
  end
  X=X(~isbadch,:,:);
  if ( ~isempty(ch_names) ) % update the channel info
    if ( ~isempty(ch_pos) ) ch_pos  =ch_pos(:,~isbadch(1:numel(ch_names))); end;
    ch_names=ch_names(~isbadch(1:numel(ch_names)));
  end
  fprintf('%d ch removed\n',sum(isbadch));
end

              %3.a) Spatial filter/re-reference (data-dependent-unsupervised)
sftype='';if( ischar(opts.spatialfilter) ) sftype=lower(opts.spatialfilter); end;
adaptspatialfiltstate=[];
R=1; % the composed spatial filter to apply.  N.B. R is applied directly as: X = R*X
if( strncmpi(opts.spatialfilter,'car',numel('car')))
  fprintf('3) CAR\n');
  Rc=eye(size(X,1))-(1./size(X,1));
  X =tprod(X,[-1 2 3],Rc,[1 -1]); % filter the data
  R = Rc*R; % compose the combined filter for test time
end;  
if( any(strfind(sftype,'slap')) )
  fprintf('3) Slap\n');
  if ( ~isempty(ch_pos) )       
    Rs=sphericalSplineInterpolate(ch_pos,ch_pos,[],[],'slap');%pre-compute the SLAP filter we'll use
    X =tprod(X,[-1 2 3],Rs,[1 -1]); % filter the data
    R = Rs*R; % compose the combined filter for test time
  else
    warning('Cant compute SLAP without channel positions!'); 
  end
end
if ( isnumeric(opts.spatialfilter) ) % user gives exact filter to use
  R=opts.spatialfilter;
  X =tprod(X,[-1 2 3],R,[1 -1]); % filter the data
end;
if( any(strfind(sftype,'wht')) || any(strfind(sftype,'whiten')) )
  fprintf('3) whiten\n');
  Rw=whiten(X,1,1,0,0,1); % symetric whiten
  X =tprod(X,[-1 2 3],Rw,[1 -1]); % filter the data
  R = Rw*R; % compose the combined filter for test time
end
if( isequal(R,1) ) R=[]; end; % if no-static filter then clear it
if ( size(X,1)>=4 && ...
     (any(strcmpi(opts.spatialfilter,{'trwht','adaptspatialfilt','adaptspatialfiltFn'})) || ...
      ~isempty(opts.adaptspatialfiltFn) ) )
  fprintf('3) adpatFilt');
  % BODGE: re-write as a std adpative spatial filter call
  if ( strcmpi(opts.spatialfilter,'trwht') ) % single-trial whitening -> special adapt-whiten
    opts.spatialfilter='adaptspatialfilt'; opts.adaptspatialfiltFn={'adaptWhitenFilt' 'dim',[1 2 3],'covFilt',0};
  end
  if( isnumeric(opts.adaptspatialfiltFn) ) opts.adaptspatialfiltFn={'adaptWhitenFilt' 'dim',[1 2 3],'covFilt',opts.adaptspatialfiltFn}; end;
  if( ~iscell(opts.adaptspatialfiltFn) ) opts.adaptspatialfiltFn={opts.adaptspatialfiltFn}; end;
  fprintf(' %s\n',opts.adaptspatialfiltFn{1});
  [X,adaptspatialfiltstate]=feval(opts.adaptspatialfiltFn{1},X,opts.adaptspatialfiltstate,opts.adaptspatialfiltFn{2:end},'ch_names',ch_names,'ch_pos',ch_pos);
  if( isfield(adaptspatialfiltstate,'R') ) R=adaptspatialfiltstate.R; end;
  fprintf('\n');
end

%2.2) time range selection
timeIdx=[];
if ( ~isempty(opts.timeband_ms) ) 
  timeIdx = opts.timeband_ms * fs ./1000; % convert to sample indices
  timeIdx = max(min(round(timeIdx),size(X,2)),1); % ensure valid range
  timeIdx = int32(timeIdx(1):timeIdx(2));
  X    = X(:,timeIdx,:);
end

%3) Spatial filter/re-reference, potentially data dependent
%3.b) Spatial filter/re-reference (data-independent / supervised)
if ( size(X,1)>=4 ) % only spatial filter if enough channels
  if( any(strfind(sftype,'csp')) )
    fprintf('3) csp\n');
    nf=str2num(sftype(end)); if ( isempty(nf) ) nf=3; end;
    [Rc,d]=csp(X,Y,3,nf); % 3 comp for each class CSP [oldCh x newCh x nClass]
    Rc=Rc(:,:)'; % [ newCh x oldCh ], N.B. R is applied directly: X = R*X
    ch_pos=[]; 
    % re-name channels
    ch_names={};for ci=1:size(d,1); for clsi=1:size(d,2); ch_names{ci,clsi}=sprintf('SF%d.%d',clsi,ci); end; end;

    X=tprod(X,[-1 2 3],Rc,[1 -1]); % filter the data
    R = Rc*R; % compose the combined filter for test time    
  end
  if( any(strfind(sftype,'ssep')) )
    fprintf('3) SSEP\n'); % est spatial filter using the SSEP approach
    nf=str2num(sftype(end)); if ( isempty(nf) ) nf=2; end;
    if ( iscell(opts.freqband) ) 
      periods = fs./[opts.freqband{:}];
    else
      if ( numel(opts.freqband)==2 ) passband=opts.freqband; else passband=opts.freqband([2 3]); end;
      periods = fs./[passband(1):passband(2)];
    end
    % Now find the ssep filt
    [Rs,s]=ssepSpatFilt(X,[1 2],periods); % R=[ch x newCh]    
    Rs=Rs(:,1:nf);     % only keep the best 2 filters
    Rs=Rs'; % [ newCh x ch]
    if ( strcmp('car',sftype(1:min(end,3))) ) R=R*Rcar; end    % include the effect of the CAR
    ch_pos=[]; ch_names={}; for ci=1:size(R,1); ch_names{ci}=sprintf('SF%d',ci); end; % re-name channels

    X=tprod(X,[-1 2 3],Rs,[1 -1]); % filter the data
    R = Rs*R; % compose the combined filter for test time    
  end
end

%3.5) Bad trial removal
isbadtr=[]; trthresh=[];
if ( opts.badtrrm ) 
  fprintf('2.5) bad trial removal');
  [isbadtr,trstds,trthresh]=idOutliers(X,3,opts.badtrthresh);
  X=X(:,:,~isbadtr);
  Y=Y(~isbadtr,:);
  fprintf(' %d tr removed\n',sum(isbadtr));
end;

                  %4) welch to convert to spectrogram = time-frequency decomp
% N.B. X = [ ch x freq x window x epoch ]
fprintf('4) Spectrogram\n');
if(isempty(opts.step_ms))opts.step_ms=opts.width_ms/2;end;
[Xt]=subsample(X,ceil(size(X,2)./opts.fs*1000./opts.step_ms),2); % raw-subsampled in time
[X,start_samp,freqs,winFn,wopts]=spectrogram(X,2,'width_ms',opts.width_ms,'windowType',opts.windowType,'fs',fs,...
                                             'step_ms',opts.step_ms,'detrend',1);
times=start_samp*1000/fs;


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
    [ans,fIdx(1)]=min(abs(freqs-max(freqs(1),  opts.freqband(1)))); % lower frequency bin
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
  X=X(:,fIdx,:,:); % sub-set to the interesting frequency range
  freqs=freqs(fIdx); % update labelling info
end;

                         % add the raw downsampled time to the frequency info
if ( opts.timefeat )
  Xt=reshape(Xt,[size(Xt,1),1,size(Xt,2),size(Xt,3)]); if(size(Xt,3)>size(X,3)) Xt=Xt(:,:,1:size(X,3),:); end;
  X=cat(2,Xt,X);
  freqs=[0 freqs]; % mark as the 0-hz signal
end

% 5.9) Apply a feature filter post-processor if wanted
featFiltFn=opts.featFiltFn; featFiltState=[];
if ( ~isempty(featFiltFn) )
  fprintf('5.5) Filter features\n');
  if ( ~iscell(featFiltFn) ) featFiltFn={featFiltFn}; end;
  for ei=1:size(X,3);
	 [X(:,:,ei),featFiltState]=feval(featFiltFn{1},X(:,:,:,ei),featFiltState,featFiltFn{2:end});
  end
end

%5.5) Visualise the input?
aucfig=[];erpfig=[];
if ( opts.visualize )
  % Compute the labeling and set of sub-problems and classes to plot
  Yidx=Y; sidx=[]; labels=opts.class_names; auclabels=labels;
  if ( size(Y,2)==1 && ~(isnumeric(Y) && ~opts.zeroLab && all(Y(:)==1 | Y(:)==0 | Y(:)==-1)))%convert from labels to 1vR sub-problems
    uY=unique(Y,'rows'); Yidx=-ones([size(Y,1),numel(uY)],'int8');    
    for ci=1:size(uY,1); 
      if(iscell(uY)) 
        tmp=strmatch(uY{ci},Y); Yidx(tmp,ci)=1; 
      else 
        for i=1:size(Y,1); Yidx(i,ci)=isequal(Y(i,:),uY(ci,:))*2-1; end
      end;
      if ( isempty(labels) || numel(labels)<ci || isempty(labels{ci}) ) 
        if ( iscell(uY) ) labels{1,ci}=uY{ci}; else labels{1,ci}=sprintf('%d',uY(ci,:)); end
        auclabels{1,ci}=labels{1,ci};
        labels{1,ci} = sprintf('%s (%d)',labels{1,ci},sum(Yidx(:,ci)>0));
      end
    end
  else
    if ( isempty(labels) ) 
      for spi=1:size(Yidx,2); 
        labels{1,spi}=sprintf('sp%d +',spi);labels{2,spi}=sprintf('sp%d -',spi); 
        auclabels{spi}=sprintf('sp%d',spi);
      end;
    end
  end
  % Compute the averages and per-sub-problem AUC scores
  mu=[];
  for spi=1:size(Yidx,2);
    Yci=Yidx(:,spi);
    if( size(labels,1)==1 ) % plot sub-prob positive response only
      mu(:,:,:,spi)=sum(X(:,:,:,Yci>0),4)./sum(Yci>0);      
    else % pos and neg sub-problem average responses
      mu(:,:,:,1,spi)=sum(X(:,:,:,Yci>0),4)./sum(Yci>0); mu(:,:,:,2,spi)=sum(X(:,:,:,Yci<0),4)./sum(Yci<0);
    end
    % if not all same class, or simple binary problem
    if(~(all(Yci(:)==Yci(1))) && ~(spi>1 && all(Yidx(:,1)==-Yidx(:,spi)))) 
      [aucci,sidx]=dv2auc(Yci,X,4,sidx); % N.B. re-seed with sidx to speed up later calls
      aucesp=auc_confidence(sum(Yci~=0),single(sum(Yci>0))./single(sum(Yci~=0)),.2);
      aucci(aucci<.5+aucesp & aucci>.5-aucesp)=.5;% set stat-insignificant values to .5
      auc(:,:,:,spi)=aucci;
    end
   end
   % Actually plot the data and AUC scores
	xy=ch_pos; if (size(xy,1)==3) xy = xyz2xy(xy); end
   erpfig=figure(2);clf(erpfig);set(erpfig,'Name','Data Visualisation: SPECT');
   yvals=freqs;
   %try; 
	  image3d(mu(:,:,:,:),1,'plotPos',xy,'Xvals',ch_names,'ylabel','freq(Hz)','Yvals',yvals,'zlabel','time+class','Zvals',times,'disptype','imaget','ticklabs','sw','clabel',opts.aveType);
     saveaspdf('ERSP'); 
	%catch; 
   %   le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	%end;
   if ( ~(all(Yci(:)==Yci(1))) )
    aucfig=figure(3);clf(aucfig);set(aucfig,'Name','Data Visualisation: SPECT AUC');
    try; 
		image3d(auc,1,'plotPos',xy,'Xvals',ch_names,'ylabel','freq(Hz)','Yvals',yvals,'zlabel','time+class','Zvals',times,'disptype','imaget','ticklabs','sw','clim',[.2 .8],'clabel','auc');
		colormap ikelvin; 
		saveaspdf('AUC'); 
	 catch; 
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  if ( ~isempty(le.stack) ) fprintf('%s>%s : %d',le.stack(1).file,le.stack(1).name,le.stack(1).line);end
	  end;
   end
   drawnow;
   figure(erpfig);
end

%6) train classifier
if ( opts.classify ) 
  fprintf('6) train classifier\n');
  [clsfr, res]=cvtrainLinearClassifier(X,Y,[],opts.nFold,'zeroLab',opts.zeroLab,'verb',opts.verb,'objFn','mlr_cg','binsp',0,'spMx','1vR',varargin{:});  
  res.isbadtr=isbadtr; % record the list of found bad trials
else
  res=[];
  clsfr=struct();
end

if ( opts.visualize ) 
  if ( size(res.tstconf,2)==1 ) % confusion matrix is correct
     % plot the confusion matrix
    confMxFig=figure(4); set(confMxFig,'name','Class confusion matrix');	 
	 if ( size(clsfr.spMx,1)==1 )
		if ( iscell(clsfr.spKey) ) clabels={clsfr.spKey{clsfr.spMx>0} clsfr.spKey{clsfr.spMx<0}};
		else                       clabels={sprintf('%g',clsfr.spKey(clsfr.spMx>0)) sprintf('%g',clsfr.spKey(clsfr.spMx<0))};
		end
	 else                         [ans,li]=find(clsfr.spMx>0); clabels=clsfr.spKey(li);
	 end
    cfMx=reshape(res.tstconf(:,1,res.opt.Ci),sqrt(size(res.tstconf,1)),[]);
    imagesc(cfMx);
    set(gca,'xtick',1:numel(clabels),'xticklabel',clabels,...
        'ytick',1:numel(clabels),'yticklabel',clabels,'clim',[0 max(sum(cfMx,1))]);
    xlabel('True Class'); ylabel('Predicted Class'); colorbar;
    title('Class confusion matrix');
  end
end


%7) combine all the info needed to apply this pipeline to testing data
clsfr.type        = 'spect';
clsfr.fs          = fs;   % sample rate of training data
clsfr.detrend     = opts.detrend; % detrend?
clsfr.isbad       = isbadch;% bad channels to be removed
clsfr.spatialfilt = R;    % spatial filter used for surface laplacian
clsfr.adaptspatialfiltFn=opts.adaptspatialfiltFn; % record the function to use
clsfr.adaptspatialfiltstate=adaptspatialfiltstate;

clsfr.filt         = []; % DUMMY -- so ERP and ERSP classifier have same structure fields
clsfr.outsz        = []; % DUMMY -- so ERP and ERSP classifier have same structure fields
clsfr.timeIdx      = timeIdx; % time range to apply the classifer to

clsfr.windowFn     = winFn;% temporal window prior to fft
clsfr.welchAveType = opts.aveType;% other options to pass to the welchpsd
clsfr.spectstep_ms = opts.step_ms;
clsfr.freqIdx      = fIdx; % start/end index of frequencies to keep
clsfr.featFiltFn   = featFiltFn; % feature normalization type
clsfr.featFiltState= featFiltState;  % state of the feature filter

clsfr.badtrthresh = []; if ( ~isempty(trthresh) && opts.badtrscale>0 ) clsfr.badtrthresh = trthresh(end)*opts.badtrscale; end
clsfr.badchthresh = []; if ( ~isempty(chthresh) && opts.badchscale>0 ) clsfr.badchthresh = chthresh(end)*opts.badchscale; end
% record some dv stats which are useful
if( ~isempty(res) ) 
  tstf = res.tstf(:,res.opt.Ci); % N.B. this *MUST* be calibrated to be useful
  %                   [pos-class    neg-class     pooled]
  clsfr.dvstats.N  =[sum(res.Y>0) sum(res.Y<=0) numel(res.Y)]; 
  clsfr.dvstats.mu =[mean(tstf(res.Y(:,1)>0)) mean(tstf(res.Y(:,1)<=0)) mean(tstf)];
  clsfr.dvstats.std=[std(tstf(res.Y(:,1)>0))  std(tstf(res.Y(:,1)<=0))  std(tstf)];
%  bins=[-inf -200:5:200 inf]; clf;plot([bins(1)-1 bins(2:end-1) bins(end)+1],[histc(tstf(Y>0),bins) histc(tstf(Y<=0),bins)]); 
end

if ( opts.visualize >= 1 ) 
  summary='';
  if ( clsfr.binsp ) % print individual classifier outputs with info about what problem it is
     for spi=1:size(res.opt.tst,2);
        summary = [summary sprintf('%-40s=\t\t%4.1f\n',clsfr.spDesc{spi},res.opt.tst(:,spi)*100)];
     end
     summary=[summary sprintf('---------------\n')];
  end
  summary=[summary sprintf('\n%40s = %4.1f','<ave>',mean(res.opt.tst,2)*100)];
  b=msgbox({sprintf('Classifier performance :\n %s',summary) 'OK to continue!'},'Results');
  if ( opts.visualize > 1 )
     for i=0:.2:120; if ( ~ishandle(b) ) break; end; drawnow; pause(.2); end; % wait to close auc figure
     if ( ishandle(b) ) close(b); end;
   end
   drawnow;
end

return;

%---------------------------------
function xy=xyz2xy(xyz)
% utility to convert 3d co-ords to 2-d ones
% search for center of the circle defining the head
cent=mean(xyz,2); cent(3)=min(xyz(3,:)); 
f=inf; fstar=inf; tstar=0; 
for t=0:.05:1; % simple loop to find the right height..
   cent(3)=t*(max(xyz(3,:))-min(xyz(3,:)))+min(xyz(3,:));
   r2=sum(repop(xyz,'-',cent).^2); 
   f=sum((r2-mean(r2)).^2); % objective is variance in distance to the center
   if( f<fstar ) fstar=f; centstar=cent; end;
end
cent=centstar;
r = abs(max(abs(xyz(3,:)-cent(3)))*1.1); if( r<eps ) r=1; end;  % radius
h = xyz(3,:)-cent(3);  % height
rr=sqrt(2*(r.^2-r*h)./(r.^2-h.^2)); % arc-length to radial length ratio
xy = [xyz(1,:).*rr; xyz(2,:).*rr];
return
%---------------------------------------
function testCase()
z=jf_mksfToy('Y',sign(round(rand(600,1))-.5));
[clsfr,res]=train_spect_clsfr(z.X,z.Y,'fs',z.di(2).info.fs,'ch_pos',[z.di(1).extra.pos3d],'ch_names',z.di(1).vals,'freqband',[0 .1 10 12],'visualize',0,'verb',1);
% multi-class example
[clsfr,res]=train_spect_clsfr(z.X,z.Y,'badtrrm',0,'capFile','cap_im_dense_subset.txt','overridechnms',0,'ch_names',z.di(1).vals,'fs',z.di(2).info.fs,'spatialfilter','car+wht','detrend',1,'freqband',[8 28],'objFn','mlr_cg','binsp',0)
[fmc,f]=apply_spect_clsfr(z.X,clsfr);
mad(res.opt.f,f)

% try with 3 class problem
[clsfr,res]=train_spect_clsfr(z.X,ceil(rand(size(z.Y,1),1)*2.9),'fs',z.di(2).info.fs,'ch_pos',[z.di(1).extra.pos3d],'ch_names',z.di(1).vals,'freqband',[0 .1 10 12],'visualize',0,'verb',1);

% try with pre-built set of sub-problems
[clsfr]=train_spect_clsfr(z.X,[z.Y sign(randn(size(z.Y)))],'fs',z.di(2).info.fs,'ch_pos',[z.di(1).extra.pos3d],'ch_names',z.di(1).vals,'freqband',[0 .1 10 12],'visualize',1,'verb',1);


										  % apply to jf_obj
Yl = cat(1,z.Ydi(1).extra.marker); Yl={Yl.value}; Yl=Yl(:); % string labels...
uY=unique(Yl);spMx={uY(1:end-1)};
[clsfr,res,X,Y]=train_spect_clsfr(z.X,Yl,'fs',z.di(2).info.fs,'ch_names',z.di(1).vals,'badCh',~[z.di(1).extra.iseeg],'width_ms',250,'freqband',freqband,'binsp',0,'objFn','mlr_cg','spMx',spMx)
										  % off-line equivalent
zpp=jf_retain(jf_welchpsd(jf_whiten(jf_rmOutliers(jf_detrend(z),'dim','ch')),'width_ms',250),'dim','freq','range','between','vals',[8 28]);
jf_cvtrain(zpp,'objFn','mlr_cg','binsp',0,'spMx',spMx);
