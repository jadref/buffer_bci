function [X,state,info]=artChRegress(X,state,dim,idx,varargin);
% remove any signal correlated with the input signals from the data
% 
%   [X,state,info]=artChRegress(X,state,dim,idx,...);% incremental calling mode
%
% N.B. important for this regression to ensure only the **pure** artifact signal goes into removal.  
%      Thus use the pre-processing options ('detrend','center','bands') to do some additional 
%      pre-processing before the removal
%
% Inputs:
%  X   -- [n-d] the data to be deflated/art channel removed
%  state -- [struct] internal state of the filter. Init-filter if empty.   ([])
%  dim -- dim(1) = the dimension along which to correlate/deflate ([1 2 3])
%         dim(2) = the time dimension for spectral filtering/detrending along
%         dim(3) = compute regression separately for each element on this dimension
%  idx -- [1 x nArt] the index/indicies along dim(1) to use as artifact channels ([])
%        OR
%         {'str' 1 x nArt} names of the artifact channels.  These will be matched with the 'ch_names' option.
%           with any missing names ignored.  Note: in the absence of an exact match *any* channel with the same prefix will be matched
% Options:
%  artFiltType -- type of additional temporal filter to apply to the artifact signals before ('fft')
%                 regressing them out. one-of 'fft'=fftfilter, 'iir'=butterworth filter
%  bands   -- spectral filter (as for fftfilter) to apply to the artifact signal ([])
%             N.B. this should be such that the filtered artifact channel as as close to the pure
%                  propogated artifact as you can get..
%  fs  -- the sampling rate of this data for the time dimension ([])
%         N.B. fs is only needed if you are using a spectral filter, i.e. bands.
%  detrend -- detrend the artifact before removal                        (0)
%  center  -- [int] center in time (0-mean) the artifact signal before removal (2)
%               center=1 : normal center, center=2 : median-center
%       N.B. if using detrend/center please call with large enough time blocks
%            that an artifact is a small part of the time...
%  covFilt -- {str} function to apply to the computed covariances to smooth them prior to regression {''}
%              SEE: biasFilt for example function format
%            OR
%             [float] half-life to use for simple exp-moving average filter
%                   N.B. this time-constant needs to be *long* enough to get a robust cross-channel
%                   covariance estimate, but *short* enough to respond to transient artifacts which 
%                   appear and disappear.  For eye-artifacts a number of about .5-1s works well.
%                   Note: alpha = exp(log(.5)./(half-life)), half-life = log(.5)/log(alpha)
%  ch_names -- {'str' size(X,dim(1))} cell array of strings of the names of the channels in dim(1) of X
%  ch_pos   -- [3 x size(X,dim(1))] physical positions of the channels in dim(1) of X
%
% TODO:
%    [] Correct state propogate over calls for the EOG data pre-processing, i.e. convert to IIR/Butter for band-pass
%    [] Spatio-temporal learning - learn the optimal spectral filter as well as spatial
%    [] Switching-mode removal   - for transient artifacts add artifact detector to only learn covariance function when artifact is present..
opts=struct('detrend',0,'center',2,'bands',[],'artfilttype','iir','fs',[],'verb',0,'covFilt',[],'filtstate',[],'ch_names',[],'ch_pos',[],'pushbackartsig',1);
if( ~isempty(state) && isstruct(state) ) % called with a filter-state, incremental filtering mode
  % extract the arguments/state
  opts    =state;
  dim     =state.dim;
  idx     =state.idx;
  artFilt =state.artFilt;
else % normal option string call
  [opts]=parseOpts(opts,varargin);
  artFilt=[];
                   % convert idx-channel names into channel numbers if needed
  if ( iscell(idx) && ~isempty(opts.ch_names) )
    % find the matching entries
    tmp=idx; idx=[];
    for ii=1:numel(tmp);
      mi=strcmp(tmp{ii},opts.ch_names); % exact match
      if( ~any(mi) ) mi=strcmpi(tmp{ii},opts.ch_names); end; % case-insensitive
      if( ~any(mi) ) mi=strncmpi(tmp{ii},opts.ch_names,numel(tmp{ii})); end; % prefix+case-insenstive
      if ( any(mi) ) mi=find(mi); idx=[idx;mi]; end
      if( opts.verb>=0 )
        if( any(mi) ) fprintf('artChRegress:: %s -> %s\n',tmp{ii},sprintf('%s,',opts.ch_names{mi}));
        else          fprintf('artChRegress:: %s unmatched\n',tmp{ii});
        end
      end;
    end
    if ( isempty(idx) )
      fprintf('artChRegress:: Warning, no artifact channels given!');
    end
  end
end
if ( isempty(idx) )% create empty state and return
  state         =opts;  state.dim     =dim;   state.idx     =idx;
  state.artFilt =[];    state.covFilt =[];    state.filtstate=[];
  info = [];
  return;
end

dim(dim<0)=ndims(X)+1+dim(dim<0);
if( isempty(dim) ) dim=[1 2 3]; end;
if( numel(dim)<2 ) dim(2)=dim(1)+1; end;
szX=size(X); szX(end+1:max(dim))=1;
if( numel(dim)<3 ) nEp=1; else nEp=szX(dim(3)); end;
issingle=isa(X,'single'); % is x single precision?

% compute the artifact signal and its forward propogation to the other channels
% N.B. convert to use IIR to allow high-pass between calls with small windows...
if ( isempty(artFilt) && ~isempty(opts.bands) ) % smoothing filter applied to art-sig before we use it
  fs=opts.fs;
  if( isempty(fs) ) warning('Sampling rate not specified.... using default=100Hz'); fs=100; end;
  if( strcmpi(opts.artfilttype,'fft') )
     if( opts.verb>=0 ) fprintf('artChRegress::Filtering @%gHz with [%s]\n',fs,sprintf('%g ',opts.bands)); end;
     artFilt = mkFilter(floor(szX(dim(2))./2),opts.bands,fs/szX(dim(2)));
  else % setup an IIR filter, so allows filter state propogation between calls
     type=opts.artfilttype;
     bands=opts.bands;
     fprintf('artChRegress::');
     if( numel(bands)>2 ) bands=bands(2:3); end;
     if( bands(1)<=0 )      type='low';  bands=bands(2);  fprintf('low-pass %gHz\n',bands); % low-pass
     elseif( bands(2)>=fs ) type='high'; bands=bands(1);  fprintf('high-pass %gHz\n',bands);% high-pass
     else                                                 fprintf('band-pass [%g-%g]Hz\n',bands);
     end
     % N.B. we use a low-order butterworth to minimise the phase-lags introduced...
     if( any(strcmpi(type,{'bandpass','iir'})) ) type=[]; end;
     if( isempty(type) )    [B,A]=butter(3,bands*2/fs); % arg, weird bug in octave for pass
     else                   [B,A]=butter(3,bands*2/fs,type);
     end
     artFilt=struct('B',B,'A',A,'filtstate',[]);
  end
end

                                % set-up the covariance filtering function
covFilt=opts.covFilt; filtstate=opts.filtstate;
if( ~isempty(covFilt) )
  if( ~iscell(covFilt) ) covFilt={covFilt}; end;
  if( isnumeric(covFilt{1}) ) % covFilt{1} is alpha for move-ave
    if(covFilt{1}>=1) covFilt{1}=exp(log(.5)./covFilt{1}); end; % convert half-life to alpha
    if(isempty(filtstate) ) filtstate=struct('N',0,'sxx',0,'sxy',0); end;
  else
    filtstate=struct('XX',[],'XY',[]); % 2 states for the 2 filters we use
  end
end

% make a index expression to extract the current epoch
xidx  ={}; for di=1:numel(szX); xidx{di}=int32(1:szX(di)); end;
% index expression to extract the artifact channels
artIdx  ={}; for di=1:numel(szX); artIdx{di}=int32(1:szX(di));end; artIdx{dim(1)}=idx; if( numel(dim)>2 ) artIdx{dim(3)}=1;  end;
% tprod-arguments for computing the channel-covariance matrix
tpIdx  = -(1:ndims(X)); tpIdx(dim(1)) =1; 
tpIdx2 = -(1:ndims(X)); tpIdx2(dim(1))=2; 

sf=[];
if ( opts.verb>=0 && nEp>10 ) fprintf('artChRegress:'); end;
for epi=1:nEp; % loop over epochs
  if ( opts.verb>=0 && nEp>10 ) textprogressbar(epi,nEp); end;

                                % extract the data for this epoch
  if( numel(dim)>2 ) % per-epoch mode
    xidx{dim(3)}=epi;
    Xei   = X(xidx{:});
  else % global mode
    Xei   = X;
  end;
  
  % extract the artifact signals for this epoch
  artSig=Xei(artIdx{:});
  if(issingle) artSig=double(artSig); end;
  % pre-process the artifact signals as wanted
  if(isequal(opts.center,1))     artSig= repop(artSig,'-',mean(artSig,dim(2))); 
  elseif(isequal(opts.center,2)) artSig= repop(artSig,'-',median(artSig,dim(2))); 
  end;
  if ( opts.detrend )      artSig = detrend(artSig,dim(2)); end;
  if ( ~isempty(artFilt) ) % smooth the result  
     if( isstruct(artFilt) ) % IIR
        if( isempty(artFilt.filtstate) ) % pre-warm the filter state
           [ans,artFilt.filtstate]=filter(B,A,repmat(mean(artSig,2),[1,size(artSig,2)]),[],dim(2));
        end
        [artSig,artFilt.filtstate]=filter(artFilt.B,artFilt.A,artSig,artFilt.filtstate,dim(2));
     else % fftFilter
        artSig = fftfilter(artSig,artFilt,[],dim(2),1); 
     end
  end 
  % push-back pre-processing changes
  if(opts.pushbackartsig&&(opts.detrend||opts.center||~isempty(artFilt)))  
     Xei(artIdx{:})=artSig;  
  end 
                                          % compute the artifact covariance
  BXXtB  = tprod(artSig,tpIdx,[],tpIdx2); % cov of the artifact signal: [nArt x nArt]
                                % get the artifact/channel cross-covariance
  BXYt   = tprod(artSig,tpIdx,Xei,tpIdx2); % cov of the artifact signal: [nArt x nCh]

                           % smooth the covariance filter estimates if wanted
  if( ~isempty(covFilt) )
    if( isnumeric(covFilt{1}) ) % move-ave
      alpha        = covFilt{1};
      alpha        = alpha.^size(Xei,dim(2)); % specified in data-packets

      filtstate.N  = alpha.*filtstate.N  + (1-alpha).*1;      % update weight
      filtstate.sxx= alpha.*filtstate.sxx+ (1-alpha).*BXXtB; 
      filtstate.sxy= alpha.*filtstate.sxy+ (1-alpha).*BXYt;  
      BXXtB        = filtstate.sxx./filtstate.N; % move-ave with warmup-protection
      BXYt         = filtstate.sxy./filtstate.N; % move-ave with warmup-protection
    else
      [BXXtB,filtstate.XX]=feval(covFilt{1},BXXtB,filtstate.XX,covFilt{2:end});
      [BXYt,filtstate.XY] =feval(covFilt{1},BXYt, filtstate.XY,covFilt{2:end});
    end
  end    
  
  % regression solution for estimateing X from the artifact channels: w_B = (B^TXX^TB)^{-1} B^TXY^T = (BX)\Y
  %w_B    = BXXtB\BXYt; % slower, min-norm, low-rank robust(ish) [nArt x nCh]
  w_B    = pinv(BXXtB)*BXYt; % slower, min-norm, low-rank robust(ish) [nArt x nCh]
  w_B(:,idx)=0; % don't modify the art-channels..
  
  % make a single spatial filter to remove the artifact signal in 1 step
  %  X-w*X = X*(I-w)
  sf       = eye(size(X,dim(1))); % [nCh x nCh]
  sf(idx,:)= sf(idx,:)-w_B; % [nCh x nCh] % insert in place to get a full-channel-set spatial filter

                                % apply the deflation
  if( nEp>1 ) % per-epoch mode, update in-place
    X(xidx{:}) = tprod(sf,[-dim(1) dim(1)],Xei,[1:dim(1)-1 -dim(1) dim(1)+1:ndims(X)]);    
  else % global regression mode
    if(opts.pushbackartsig&&(opts.detrend||opts.center||~isempty(artFilt)))  
       X(artIdx{:})=artSig; % push-back pre-processing changes
    end 
    X = tprod(sf,[-dim(1) dim(1)],X,[1:dim(1)-1 -dim(1) dim(1)+1:ndims(X)]);
    if(issingle) X=single(X); end; % get back to single precision
  end
end %epoch loop
if ( opts.verb>=0 && nEp>10 ) fprintf('\n'); end;

% update the filter state
state         =opts;
state.R       =sf;
state.dim     =dim;
state.idx     =idx;
state.artFilt =artFilt;
state.covFilt =covFilt;
state.filtstate=filtstate;
info = struct('artSig',artSig);
return;
%--------------------------------------------------------------------------
function testCase()
S =randn(10,1000,100);% sources
sf=randn(10,2);% per-electrode spatial filter
%S(1:size(sf,2),:)=cumsum(S(1:size(sf,2),:),2); % artifact is 'high-frequency'
N =cumsum(randn(size(sf,2),size(S,2),size(S,3)),2); % additional non-propogated artifact noise, 'low-frequency'
X =S+reshape(sf*S(1:size(sf,2),:),size(S)); % source+propogaged noise
X(1:size(sf,2),:,:)=X(1:size(sf,2),:,:)+N;

Y =artChRegress(X,[],1,[1 2],'center',0); % global mode
tmp=cat(4,S,S-X,Y-S);clf;mimage(squeeze(mean(abs(tmp(size(sf,2)+1:end,:,:,:)),3)),'clim',[0 mean(abs(tmp(:)))],'colorbar',1,'title',{'S','S-X','S-Y'}); colormap ikelvin
clf;mimage(squeeze(tmp(:,:,1,:)),'title',{'S','S-X','S-Y'},'colorbar',1)
Y2=artChRm(X,1,[1 2]);
clf;mimage(S,Y2-S,'clim','cent0','colorbar',1); colormap ikelvin

                                % regress per-epoch
[Y,info] =artChRegress(X,[],[1 2 3],[1 2]);

                                % incremental regress per-epoch
[Yi(:,:,1),state]=artChRegress(X(:,:,1),[],[1 2 3],[1 2]);
for epi=2:size(X,3);
  textprogressbar(epi,size(X,3));
  [Yi(:,:,epi),state]=artChRegress(X(:,:,epi),state);
end
mad(Y,Yi)

% with additional artifact channel pre-filtering
Y =artChRegress(X,[],1,[1 2],'fs',100,'center',0,'bands',[0 10 inf inf],'artfilttype','fft'); % fft-prefilter
Y =artChRegress(X,[],1,[1 2],'fs',100,'center',0,'bands',[0 10 inf inf],'artfilttype','iir'); % iir


                                % specify channels with names mode
[Y,info]=artChRegress(X,[],[],{'C1','C2'},'ch_names',{'C1','C2','C3','C4','C5','C6','C7','C8','C9','C10'});
