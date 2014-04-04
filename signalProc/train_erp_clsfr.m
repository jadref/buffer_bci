function [clsfr,res,X,Y]=train_erp_clsfr(X,Y,varargin)
% train a simple ERP classifer.
% 
% [clsfr,res,X]=train_erp_clsfr(X,Y....);
%
% Inputs:
%  X         - [ ch x time x epoch ] data set
%  Y         - [ nEpoch x 1 ] set of data class labels
% Options:
%  ch_pos    - [3 x nCh] 3-d co-ordinates of the data electrodes
%              OR
%              {str} cell array of strings which label each channel in *1010 system*
%  fs        - sampling rate of the data
%  timeband  - [2 x 1] band of times to use for classification, all if empty ([])
%  freqband  - [2 x 1] or [3 x 1] or [4 x 1] band of frequencies to use
%              EMPTY for *NO* spectral filter
%  downsample - [1x1] downsample to this frequency before use
%  spatialfilter -- [str] one of 'slap','car','none'  ('slap')
%  badchrm   - [bool] do we do bad channel removal    (1)
%  badchthresh - [float] threshold in std-dev units to id channel as bad (3.5)
%  badtrrm   - [bool] do we do bad trial removal      (1)
%  badtrthresh - [float] threshold in std-dev units to id trial as bad (3)
%  detrend   - [bool] do we detrend the data          (1)
%  classify  - [bool] do we train a classifier        (1)
%  visualize - [int] visualize the data
%               0 - don't visualize
%               1 - visualize, but don't wait
%               2 - visualize, and wait for user before continuing
%  verb      - [int] verbosity level
%  ch_names  - {str} cell array of strings which label each channel
% Outputs:
%  clsfr  - [struct] structure contining the stuff necessary to apply the trained classifier
%  res    - [struct] results structure
%  X      - [size(X)] the pre-processed data
opts=struct('classify',1,'fs',[],'timeband',[],'freqband',[],'downsample',[],'detrend',1,'spatialfilter','car',...
    'badchrm',1,'badchthresh',3.1,'badchscale',2,...
    'badtrrm',1,'badtrthresh',3,'badtrscale',2,...
    'ch_pos',[],'ch_names',[],'verb',0,'capFile','1010','overridechnms',0,...
    'visualize',2,'badCh',[],'nFold',10);
[opts,varargin]=parseOpts(opts,varargin);

di=[]; ch_pos=opts.ch_pos; ch_names=opts.ch_names;
if ( iscell(ch_pos) && isstr(ch_pos{1}) ) ch_names=ch_pos; ch_pos=[]; end;
if ( isempty(ch_pos) && (~isempty(ch_names) || opts.overridechnms) ) % convert names to positions
  di = addPosInfo(ch_names,opts.capFile,opts.overridechnms); % get 3d-coords
  ch_pos=cat(2,di.extra.pos3d); ch_names=di.vals; % extract pos and channels names
end

%1) Detrend
if ( opts.detrend )
  fprintf('1) Detrend\n');
  X=detrend(X,2); % detrend over time
end

%2) Bad channel identification & removal
isbadch=[]; chthresh=[];
if ( opts.badchrm || ~isempty(opts.badCh) )
  fprintf('2) bad channel removal, ');
  isbadch = false(size(X,1),1);
  if ( ~isempty(ch_pos) ) isbadch(numel(ch_pos)+1:end)=true; end;
  if ( ~isempty(opts.badCh) )
      isbadch(opts.badCh)=true;
      goodCh=find(~isbadch);
      if ( opts.badchrm ) 
          [isbad2,chstds,chthresh]=idOutliers(X(goodCh,:,:),1,opts.badchthresh);
          isbadch(goodCh(isbad2))=true;
      end
  elseif ( opts.badchrm ) [isbadch,chstds,chthresh]=idOutliers(X,1,opts.badchthresh); 
  end;
  X=X(~isbadch,:,:);
  if ( ~isempty(ch_names) ) % update the channel info
    ch_pos  =ch_pos(:,~isbadch(1:numel(ch_names)));
    ch_names=ch_names(~isbadch(1:numel(ch_names)));
  end
  fprintf('%d ch removed\n',sum(isbadch));
end

%3) Spatial filter/re-reference
R=[];
if ( size(X,1)> 5 ) % only spatial filter if enough channels
  switch lower( opts.spatialfilter )
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
   case 'none';
   otherwise; warning(sprintf('Unrecog spatial filter type: %s. Ignored!',opts.spatialfilter ));
  end
end
if ( ~isempty(R) ) % apply the spatial filter
  X=tprod(X,[-1 2 3],R,[1 -1]); 
end

%4) spectrally filter to the range of interest
filt=[]; 
fs=opts.fs;
outsz=[size(X,2) size(X,2)];
if(~isempty(opts.downsample)) outsz(2)=min(outsz(2),round(trlen_samp*opts.downsample/fs)); end;
if ( ~isempty(opts.freqband) && size(X,2)>10 && ~isempty(fs) ) 
  fprintf('4) filter\n');
  len=size(X,2);
  filt=mkFilter(opts.freqband,floor(len/2),opts.fs/len);
  X   =fftfilter(X,filt,outsz,2,1);
elseif( ~isempty(opts.downsample) ) % manual downsample without filtering
  X   =subsample(X,outsz(2));   
end

%4.2) time range selection
timeIdx=[];
if ( ~isempty(opts.timeband) ) 
  timeIdx = opts.timeband * fs; % convert to sample indices
  timeIdx = max(min(timeIdx,size(X,2)),1); % ensure valid range
  timeIdx = int32(timeIdx(1):timeIdx(2));
  X    = X(:,timeIdx,:);
end


%4.5) Bad trial removal
isbadtr=[]; trthresh=[];
if ( opts.badtrrm )
  fprintf('4.5) bad trial removal');
  [isbadtr,trstds,trthresh]=idOutliers(X,3,opts.badtrthresh);
  X=X(:,:,~isbadtr);
  Y=Y(~isbadtr);
  fprintf(' %d tr removed\n',sum(isbadtr));
end;

%5.5) Visualise the input?
if ( opts.visualize && ~isempty(ch_pos) )
   uY=unique(Y);sidx=[];
   for ci=1:numel(uY);
     Yci = (Y==uY(ci));
      mu(:,:,ci)=mean(X(:,:,Yci),3);
      if(~(ci>1 && numel(uY)<=2)) 
        [aucci,sidx]=dv2auc(Yci*2-1,X,3,sidx); % N.B. re-seed with sidx to speed up later calls
        aucesp=auc_confidence(numel(Y),sum(Yci)./numel(Y));
        aucci(aucci<.5+acuesp & aucci>.5-aucesp)=.5;% set stat-insignificant values to .5
        auc(:,:,ci)=aucci;
      end;
      labels{ci}=sprintf('%d',uY(ci));
   end
   times=(1:size(mu,2))/opts.fs;
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

%6) train classifier
if ( opts.classify ) 
  fprintf('6) train classifier\n');
  [clsfr, res]=cvtrainLinearClassifier(X,Y,[],opts.nFold,'zeroLab',1,varargin{:});
else
  clsfr=struct();
end

%7) combine all the info needed to apply this pipeline to testing data
clsfr.fs          = fs;   % sample rate of training data
clsfr.detrend     = opts.detrend; % detrend?
clsfr.isbad       = isbadch;% bad channels to be removed
clsfr.spatialfilt = R;    % spatial filter used for surface laplacian
clsfr.filt        = filt; % filter weights for spectral filtering
clsfr.outsz       = outsz; % info on size after spectral filter for downsampling
clsfr.timeIdx     = timeIdx; % time range to apply the classifer to

clsfr.windowFn    = []; % DUMMY -- so ERP and ERSP classifier have same structure fields
clsfr.welchAveType= []; % DUMMY -- so ERP and ERSP classifier have same structure fields
clsfr.freqIdx     = []; % DUMMY -- so ERP and ERSP classifier have same structure fields

clsfr.badtrthresh = []; if ( ~isempty(trthresh) ) clsfr.badtrthresh = trthresh(end)*opts.badtrscale; end
clsfr.badchthresh = []; if ( ~isempty(chthresh) ) clsfr.badchthresh = chthresh(end)*opts.badchscale; end
% record some dv stats which are useful
tstf = res.tstf(:,res.opt.Ci); % N.B. this *MUST* be calibrated to be useful
clsfr.dvstats.N   = [sum(Y>0) sum(Y<=0) numel(Y)]; % [pos-class neg-class pooled]
clsfr.dvstats.mu  = [mean(tstf(Y>0)) mean(tstf(Y<=0)) mean(tstf)];
clsfr.dvstats.std = [std(tstf(Y>0))  std(tstf(Y<=0))  std(tstf)];
%  bins=[-inf -200:5:200 inf]; clf;plot([bins(1)-1 bins(2:end-1) bins(end)+1],[histc(tstf(Y>0),bins) histc(tstf(Y<=0),bins)]); 

if ( opts.visualize > 1 ) 
   b=msgbox({sprintf('Classifier performance : %s',sprintf('%4.1f ',res.tstbin(:,:,res.opt.Ci)*100)) 'OK to continue!'},'Results');
   while ( ishandle(b) ) pause(.1); end; % wait to close auc figure
   if ( ishandle(aucfig) ) close(aucfig); end;
   if ( ishandle(erpfig) ) close(erpfig); end;
   if ( ishandle(b) ) close(b); end;
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
