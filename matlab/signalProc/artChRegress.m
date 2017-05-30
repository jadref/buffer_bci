function [X,state,artSig]=artChRegress(X,state,dim,idx,varargin);
% remove any signal correlated with the input signals from the data
% 
%   [X,state,artSig]=artChRegress(X,state,dim,idx,...);% incremental calling mode
%
% Inputs:
%  X   -- [n-d] the data to be deflated/art channel removed
%  state -- [struct] internal state of the filter. Init-filter if empty.   ([])
%  dim -- dim(1) = the dimension along which to correlate/deflate ([1 2])
%         dim(2) = the time dimension for spectral filtering/detrending along
%         dim(3) = compute regression separately for each element on this dimension
%  idx -- the index/indicies along dim(1) to use as artifact channels ([])
% Options:
%  bands   -- spectral filter (as for fftfilter) to apply to the artifact signal ([])
%  fs  -- the sampling rate of this data for the time dimension ([])
%         N.B. fs is only needed if you are using a spectral filter, i.e. bands.
%  detrend -- detrend the artifact before removal                        (1)
%  center  -- center in time (0-mean) the artifact signal before removal (0)
%  covFilt -- {str} function to apply to the computed covariances to smooth them prior to regression {''}
%              SEE: biasFilt for example function format
%            OR
%             [float] half-life to use for simple exp-moving average filter
opts=struct('detrend',0,'center',0,'bands',[],'fs',[],'verb',0,'covFilt',[],'filtstate',[]);
if( ~isempty(state) && isstruct(state) ) % called with a filter-state, incremental filtering mode
  % extract the arguments/state
  opts    =state;
  dim     =state.dim;
  idx     =state.idx;
  artFilt =state.artFilt;
else % normal option string call
  [opts]=parseOpts(opts,varargin);
  artFilt=[];
end

dim(dim<0)=ndims(X)+1+dim(dim<0);
if( numel(dim)<2 ) dim(2)=dim(1)+1; end;
szX=size(X); szX(end+1:max(dim))=1;
if( numel(dim)<3 ) nEp=1; else nEp=szX(dim(3)); end;

% compute the artifact signal and its forward propogation to the other channels
if ( isempty(artFilt) && ~isempty(opts.bands) ) % smoothing filter applied to art-sig before we use it
  artFilt = mkFilter(floor(szX(dim(2))./2),opts.bands,opts.fs/szX(dim(2)));
end

                                % set-up the covariance filtering function
covFilt=opts.covFilt; filtstate=opts.filtstate;
if( ~isempty(covFilt) )
  if( ~iscell(covFilt) ) covFilt={covFilt}; end;
  if( isnumeric(covFilt{1}) ) % covFilt{1} is alpha for move-ave
    if(covFilt{1}>1) covFilt{1}=exp(log(.5)./alpha); end; % convert half-life to alpha
    if(isempty(filtstate) ) filtstate=struct('N',0,'sx',0); end;
  end
end

% make a index expression to extract the current epoch
xidx  =repmat({':'},1,numel(szX)); 
% index expression to extract the artifact channels
artIdx=repmat({':'},1,numel(szX)); artIdx{dim(1)}=idx; if( numel(dim)>2 ) artidx{dim(3)}=1;  end;
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
  % pre-process the artifact signals as wanted
  if ( opts.center )       artSig = repop(artSig,'-',mean(artSig,dim(2))); end;
  if ( opts.detrend )      artSig = detrend(artSig,dim(2)); end;
  if ( ~isempty(artFilt) ) artSig = fftfilter(artSig,artFilt,[],dim(2),1); end % smooth the result  
  % compute the artifact covariance
  BXXtB  = tprod(artSig,tpIdx,[],tpIdx2); % cov of the artifact signal: [nArt x nArt]
  % smooth the covariance filter estimates if wanted
  if( ~isempty(covFilt) )
    if( isnumeric(covFilt{1}) ) % move-ave
      filtstate.N = alpha.*filtstate.N + (1-alpha).*1;      % update weight
      filtstate.sx= alpha.*filtstate.sx+ (1-alpha).*BXXtB; % update move-ave
      BXXtB       = sx./N; % move-ave with warmup-protection
    else
      [BXXtB,filtstate]=feval(covFilt{1},BXXtB,filtstate,covFilt{2:end});
    end
  end    
                                % get the artifact/channel cross-covariance
  BXYt   = tprod(artSig,tpIdx,Xei,tpIdx2); % cov of the artifact signal: [nArt x nCh]
  
  % regression solution for estimateing X from the artifact channels: w_B = (B^TXX^TB)^{-1} B^TXY^T = (BX)\Y
  w_B    = pinv(BXXtB)*BXYt; % slower, min-norm, low-rank robust(ish) [nArt x nCh]

       % make a single spatial filter to remove the artifact signal in 1 step
       %  X-w*X = X*(I-w)
  sf     = eye(size(X,dim(1))); % [nCh x nCh]
  sf(idx,:)=sf(idx,:)-w_B; % [nCh x nCh] % insert in place to get a full-channel-set spatial filter

                                % apply the deflation
  if( nEp>1 ) % per-epoch mode, update in-place
    X(xidx{:}) = tprod(sf,[-dim(1) dim(1)],Xei,[1:dim(1)-1 -dim(1) dim(1)+1:ndims(X)]);    
  else % global regression mode
    X = tprod(sf,[-dim(1) dim(1)],X,[1:dim(1)-1 -dim(1) dim(1)+1:ndims(X)]);
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
S=randn(10,1000,100);% sources
sf=randn(10,2);% per-electrode spatial filter
X =S+reshape(sf*S(1:size(sf,2),:),size(S)); % source+propogaged noise

Y =artChRegress(X,[],1,[1 2]); % global mode
clf;mimage(S,X-S,Y-S,'clim','cent0','colorbar',1,'title',{'S','S-X','S-Y'}); colormap ikelvin
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
