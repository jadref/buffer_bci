function [X,pipeline,info,opts]=preproc(X,varargin)
% simple pre-processing function
% 
% [X,pipeline,info,opts]=preproc(X,...)
%
% Inputs:
%  X         - [ ch x time x epoch ] data set
% Options:  (specify as 'name',value pairs, e.g. train_ersp_clsfr(X,Y,'fs',10);
%  Y         - [ nEpoch x 1 ] set of data class labels
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
%       WARNING: CSP is particularly prone to *overfitting* so treat any performance estimates with care...
%  badchrm   - [bool] do we do bad channel removal    (1)
%  badchthresh - [float] threshold in std-dev units to id channel as bad (3.5)
%  badtrrm   - [bool] do we do bad trial removal      (1)
%  badtrthresh - [float] threshold in std-dev units to id trial as bad (3)
%  detrend   - [int] do we detrend/center the data          (1)
%              0 - do nothing
%              1 - detrend the data
%              2 - center the data (i.e. subtract the mean)
%  visualize - [int] visualize the data
%               0 - don't visualize
%               1 - visualize, but don't wait
%               2 - visualize, and wait for user before continuing
%  verb      - [int] verbosity level
%  class_names - {str} names for each of the classes in Y in *increasing* order ([])
% Outputs:
%  X       -- [ppch x pptime x ppepoch] pre-processed data (N.B. may/will have different size to input X)
%  pipeline-- [struct] structure with parameters use to pre-process the data
%  badch   -- [bool nCh x 1] logical indicating which channels were found bad
%  badtr   -- [bool N x 1] logical indicating which trials were found bad
opts=struct('classify',1,'fs',[],'timeband',[],'freqband',[],'downsample',[],...
            'width_ms',250,'windowType','hanning','aveType','amp',...
            'detrend',1,'spatialfilter','slap',...
            'badchrm',1,'badchthresh',3.1,'badchscale',2,...
            'badtrrm',1,'badtrthresh',3,'badtrscale',2,...
            'ch_pos',[],'ch_names',[],'verb',0,'capFile','1010','overridechnms',0,...
            'visualize',1,...
            'badCh',[],'nFold',10,'class_names',[],'Y',[],'hdr',[]);
[opts,varargin]=parseOpts(opts,varargin);

% get the sampling rate
di=[]; ch_pos  =opts.ch_pos; ch_names=opts.ch_names;
if ( iscell(ch_pos) && ischar(ch_pos{1}) ) ch_names=ch_pos; ch_pos=[]; end;
if ( isempty(ch_names) && ~isempty(opts.hdr) ) % ARGH! deal with inconsistent field names in diff header vers
  if ( isfield(opts.hdr,'labels') ) ch_names=opts.hdr.labels;
  elseif( isfield(opts.hdr,'label') ) ch_names=opts.hdr.label;
  elseif( isfield(opts.hdr,'channel_names') ) ch_names=opts.hdr.channel_names; end;
end;
if ( isempty(ch_pos) && (~isempty(ch_names) || opts.overridechnms) ) % convert names to positions
  di = addPosInfo(ch_names,opts.capFile,opts.overridechnms); % get 3d-coords
  ch_pos=cat(2,di.extra.pos3d); ch_names=di.vals; % extract pos and channels names  
end
fs=opts.fs; 
if ( isempty(fs) ) 
  if ( ~isempty(opts.hdr) ) % ARGH! deal with inconsistent field names in diff header vers
    if ( isfield(opts.hdr,'fSample') ) fs=opts.hdr.fSample;
    elseif( isfield(opts.hdr,'fsample') ) fs=opts.hdr.fsample
    elseif( isfield(opts.hdr,'Fs') ) fs=opts.hdr.Fs;end
  else
    warning('No sampling rate specified... assuming fs=250'); fs=250; 
  end
end;

% convert X to 3-d if needed
if ( iscell(X) ) 
  if ( isnumeric(X{1}) ) 
    X=cat(3,X{:});
  else
    error('Unrecognised data format!');
  end
elseif ( isstruct(X) )
  X=cat(3,X.buf);
end 
Y=opts.Y; if(isempty(Y))Y=ones(size(X,3),1);end

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
if ( opts.badchrm || ~isempty(opts.badCh) )
  fprintf('2) bad channel removal, ');
  isbadch = false(size(X,1),1);
  if ( ~isempty(ch_names) )    isbadch(numel(ch_names)+1:end)=true; end;
  if ( ~isempty(opts.badCh) )  isbadch(opts.badCh)=true; end
  if ( opts.badchrm ) 
    goodCh=find(~isbadch);
    [isbad2,chstds,chthresh]=idOutliers(X(goodCh,:,:),1,opts.badchthresh);
    isbadch(goodCh(isbad2))=true;
  end
  X=X(~isbadch,:,:);
  if ( ~isempty(ch_names) ) % update the channel info
    ch_pos  =ch_pos(:,~isbadch(1:numel(ch_names)));
    ch_names=ch_names(~isbadch(1:numel(ch_names)));
  end
  fprintf('%d ch removed\n',sum(isbadch));
end


%4) spectrally filter to the range of interest
filt=[]; 
outsz=[size(X,2) size(X,2)];
if(~isempty(opts.downsample)) outsz(2)=min(outsz(2),round(size(X,2)*opts.downsample/fs)); end;
if ( ~isempty(opts.freqband) && size(X,2)>10 && ~isempty(fs) ) 
  fprintf('4) filter\n');
  len=size(X,2);
  filt=mkFilter(opts.freqband,floor(len/2),fs/len);
  X   =fftfilter(X,filt,outsz,2,1);
elseif( ~isempty(opts.downsample) ) % manual downsample without filtering
  X   =subsample(X,outsz(2));   
end

%2.2) time range selection
timeIdx=[];
if ( ~isempty(opts.timeband) ) 
  timeIdx = opts.timeband * fs; % convert to sample indices
  timeIdx = max(min(timeIdx,size(X,2)),1); % ensure valid range
  timeIdx = int32(timeIdx(1):timeIdx(2));
  X    = X(:,timeIdx,:);
end

%3) Spatial filter/re-reference
R=[];
if ( size(X,1)> 5 ) % only spatial filter if enough channels
  sftype=lower(opts.spatialfilter);
  switch ( sftype )
   case 'slap';
    fprintf('3) Slap\n');
    if ( ~isempty(ch_pos) )       
      R=sphericalSplineInterpolate(ch_pos,ch_pos,[],[],'slap');%pre-compute the SLAP filter we'll use
    else
      warning('Cant compute SLAP without channel positions!'); 
    end
   case 'car';
    fprintf('3) CAR\n');
    R=eye(size(X,1))-(1./size(X,1));
   case {'whiten','wht'};
    fprintf('3) whiten\n');
    R=whiten(X,1,1,0,0,1); % symetric whiten
   case {'csp','csp1','csp2','csp3'};
    fprintf('3) csp\n');
    nf=str2num(sftype(end)); if ( isempty(nf) ) nf=3; end;
    [R,d]=csp(X,Y,3,nf); % 3 comp for each class CSP [oldCh x newCh x nClass]
    R=R(:,:)'; % [ newCh x oldCh ]
    ch_pos=[]; 
    % re-name channels
    ch_names={};for ci=1:size(d,1); for clsi=1:size(d,2); ch_names{ci,clsi}=sprintf('SF%d.%d',clsi,ci); end; end;
   case {'ssep','car-ssep','car+ssep','ssep1','ssep2','ssep3'};
    fprintf('3) SSEP\n'); % est spatial filter using the SSEP approach
    nf=str2num(sftype(end)); if ( isempty(nf) ) nf=2; end;
    if ( iscell(opts.freqband) ) 
      periods = fs./[opts.freqband{:}];
    else
      if ( numel(opts.freqband)==2 ) passband=opts.freqband; else passband=opts.freqband([2 3]); end;
      periods = fs./[passband(1):passband(2)];
    end
    Xcar=X; % copy of data
    if ( strcmp('car',sftype(1:min(end,3))) ) % first CAR the data
      Xcar=repop(X,'-',mean(X,1));Rcar=eye(size(X,1))-(1./size(X,1));
    end
    % Now find the ssep filt
    [R,s]=ssepSpatFilt(Xcar,[1 2],periods); % R=[ch x newCh]    
    R=R(:,1:nf);     % only keep the best 2 filters
    R=R'; % [ newCh x ch]
    if ( strcmp('car',sftype(1:min(end,3))) ) R=R*Rcar; end    % include the effect of the CAR
    ch_pos=[]; ch_names={}; for ci=1:size(R,1); ch_names{ci}=sprintf('SF%d',ci); end; % re-name channels
   case 'none';
   otherwise; warning(sprintf('Unrecog spatial filter type: %s. Ignored!',opts.spatialfilter ));
  end
end
if ( ~isempty(R) ) % apply the spatial filter
  X=tprod(X,[-1 2 3],R,[1 -1]); 
end

%3.5) Bad trial removal
isbadtr=[]; trthresh=[];
if ( opts.badtrrm ) 
  fprintf('2.5) bad trial removal');
  [isbadtr,trstds,trthresh]=idOutliers(X,3,opts.badtrthresh);
  X=X(:,:,~isbadtr);
  if (~isempty(Y)) Y=Y(~isbadtr);end
  fprintf(' %d tr removed\n',sum(isbadtr));
end;

%5.5) Visualise the input?
if ( opts.visualize && ~isempty(ch_pos) )
   uY=unique(Y);sidx=[]; labels=opts.class_names;
   for ci=1:numel(uY);     
     if(iscell(uY)) tmp=strmatch(uY(ci),Y); Yci=false(size(Y)); Yci(tmp)=true; else Yci=(Y==uY(ci)); end;
      mu(:,:,ci)=mean(X(:,:,Yci),3);
      if(~(ci>1 && numel(uY)<=2)) 
        [aucci,sidx]=dv2auc(Yci*2-1,X,3,sidx); % N.B. re-seed with sidx to speed up later calls
        aucesp=auc_confidence(numel(Y),sum(Yci)./numel(Y),.2);
        aucci(aucci<.5+aucesp & aucci>.5-aucesp)=.5;% set stat-insignificant values to .5
        auc(:,:,ci)=aucci;
      end;
      if ( isempty(labels) || numel(labels)<ci || isempty(labels{ci}) ) 
        if ( iscell(uY) ) labels{ci}=uY{ci}; else labels{ci}=sprintf('%d',uY(ci)); end
      end;
   end
   times=(1:size(mu,2))/fs;
   erpfig=figure('Name','Data Visualisation: ERP');
   if ( ~isempty(di) ) xy=cat(2,di.extra.pos2d); % use the pre-comp ones if there
   elseif (size(ch_pos,1)==3) xy = xyz2xy(ch_pos);
   else   xy=[];
   end
   image3d(mu,1,'plotPos',xy,'Xvals',ch_names,'ylabel','time(s)','Yvals',times,'zlabel','class','Zvals',labels,'disptype','plot','ticklabs','sw');
   zoomplots;
   try; saveaspdf('ERP'); catch; end;
   aucfig=figure('Name','Data Visualisation: ERP AUC');
   image3d(auc,1,'plotPos',xy,'Xvals',ch_names,'ylabel','time(s)','Yvals',times,'zlabel','class','Zvals',labels,'disptype','imaget','ticklabs','sw','clim',[.2 .8]);
   colormap ikelvin; zoomplots;
   drawnow;
   try; saveaspdf('AUC'); catch; end;
end

% save the pipeline parameters
pipeline.fs          = fs;   % sample rate of training data
pipeline.detrend     = opts.detrend; % detrend?
pipeline.isbad       = isbadch;% bad channels to be removed
pipeline.spatialfilt = R;    % spatial filter used for surface laplacian
pipeline.filt        = filt; % filter weights for spectral filtering
pipeline.outsz       = outsz; % info on size after spectral filter for downsampling
pipeline.timeIdx     = timeIdx; % time range to apply the classifer to

pipeline.windowFn    = []; % DUMMY -- so ERP and ERSP classifier have same structure fields
pipeline.welchAveType= []; % DUMMY -- so ERP and ERSP classifier have same structure fields
pipeline.freqIdx     = []; % DUMMY -- so ERP and ERSP classifier have same structure fields

pipeline.badtrthresh = []; if ( ~isempty(trthresh) ) pipeline.badtrthresh = trthresh(end)*opts.badtrscale; end
pipeline.badchthresh = []; if ( ~isempty(chthresh) ) pipeline.badchthresh = chthresh(end)*opts.badchscale; end

% other info about the pre-processing
info.ch_names=ch_names;
info.ch_pos  =ch_pos;
info.badch   =isbadch;
info.badtr   =isbadtr;

return;
