function [X,state,info]=rmEMGFilt(X,state,dim,varargin);
% Spatially filter input to suppress the EMG/temporally-decorrelated activity
% 
%   [X,state,info]=rmEMG(X,state,dim,varargin)
%
% Inputs:
%  X   -- [n-d] the data to be deflated/art channel removed
%  state -- [struct] internal state of the filter. Init-filter if empty.   ([])
%  dim -- dim(1) = the dimension along which to correlate/deflate ([1 2 3])
%         dim(2) = the time dimension for spectral filtering/detrending along
%         dim(3) = compute regression separately for each element on this dimension
% Options:
%  tau_samp - time offset to use for computation of the auto-covariance (1)
%  tol           - tolerance for detection of zero eigenvalues          (1e-7)
%  minCorr       - [1x1] minumum correlation value for detection of emg feature  (.2)
%  corrStdThresh - [1x1] threshold measured in std deviations for detection of   (2.5)
%                        anomylously small correlations, which is indicative of an emg
%                        channel
%  bands   -- spectral filter (as for fftfilter) to apply to the artifact signal ([30 35 inf inf])
%  fs  -- the sampling rate of this data for the time dimension ([])
%         N.B. fs is only needed if you are using a spectral filter, i.e. bands.
%  detrend -- detrend the artifact before removal                        (1)
%  center  -- center in time (0-mean) the artifact signal before removal (0)
%  covFilt -- {str} function to apply to the computed covariances to smooth them prior to fitting {''}
%              SEE: biasFilt for example function format
%            OR
%             [float] half-life to use for simple exp-moving average filter
%
%  TODO:
%    [] - does pre-processing the signal, e.g. detrend or high-pass at 30Hz, help the removal?
%         H: With this implementation a pure-spatial filter, such pre-processing is potentially dangerous
%            when it means the filter is applied to different data from what it was trained on. e.g. if big
%            linear-trend in EMG channel and detrend before fit, then applying to the non-detrended data will
%            result in moving this linear-trend into all the other channels!
opts=struct('tau_samp',1,'tol',1e-7,'minCorr',.2,'corrStdThresh',2.5,...
            'detrend',0,'center',0,'bands',[],'fs',[],'covFilt','','filtstate',[],'filtstatetau',[],'verb',2);
if( nargin<2 ) state=[]; end;
if( nargin<3 ) dim=[]; end;
if( ~isempty(state) && isstruct(state) ) % called with a filter-state, incremental filtering mode
  % extract the arguments/state
  opts    =state;
  dim     =state.dim;
  artFilt =state.artFilt;
else % normal option string call
  [opts]=parseOpts(opts,varargin);
  artFilt=[];
end

if ( isempty(dim) ) dim=[1 2 3]; end;
dim(dim<0)=ndims(X)+1+dim(dim<0);
if ( numel(dim)<2 ) dim(2)=dim(1)+1; end;
szX=size(X); szX(end+1:max(dim))=1;
if( numel(dim)<3 ) nEp=1; else nEp=szX(dim(3)); end;

% compute the artifact signal and its forward propogation to the other channels
if ( isempty(artFilt) && ~isempty(opts.bands) ) % smoothing filter applied to art-sig before we use it
  if( isempty(opts.fs) ) warning('Sampling rate not specified.... using default=100Hz'); opts.fs=100; end;
  artFilt = mkFilter(floor(szX(dim(2))./2),opts.bands,opts.fs/szX(dim(2)));
end

                                % set-up the covariance filtering function
covFilt=opts.covFilt; filtstate=opts.filtstate; filtstatetau=opts.filtstatetau;
if( ~isempty(covFilt) )
  if( ~iscell(covFilt) ) covFilt={covFilt}; end;
  if( isnumeric(covFilt{1}) ) % covFilt{1} is alpha for move-ave
    if(covFilt{1}>1) covFilt{1}=exp(log(.5)./alpha); end; % convert half-life to alpha
    if(isempty(filtstate) )    filtstate=struct('N',0,'sxx',0,'sxxtau',0);    end;
  end
end

% N.B. index expressions with int32 or bool types are **much** faster (particularly on Octave)
% make a index expression to extract the current epoch.
xidx  ={}; for di=1:numel(szX); xidx{di}=int32(1:szX(di)); end;
% index expr for the time-lagged covariance computation
%index shift-back  by tau_samp
idxtau={};for di=1:numel(szX);idxtau{di}=int32(1:szX(di));end;idxtau{dim(2)}=1:size(X,dim(2))-opts.tau_samp;if(numel(dim)>2)idxtau{dim(3)}=1;end;
tmp=szX; tmp(dim(2))=opts.tau_samp; if(numel(dim)>2) tmp(dim(3))=1; end; padding=zeros(tmp); % zero-padding to make same size

                % tprod-arguments for computing the channel-covariance matrix
tpIdx  = -(1:ndims(X)); tpIdx(dim(1)) =1; 
tpIdx2 = -(1:ndims(X)); tpIdx2(dim(1))=2; 

% N.B. this incremental version is 2x slower than the pre-compute in blocks version....
sf=[];
if ( opts.verb>=0 && nEp>10 ) fprintf('rmEMGFilt:'); end;
for epi=1:nEp; % loop over epochs
  if ( opts.verb>=0 && nEp>10 ) textprogressbar(epi,nEp); end;

                                % extract the data for this epoch
  if( numel(dim)>2 ) % per-epoch mode
    xidx{dim(3)}=epi;
    Xei   = X(xidx{:});
  else % global mode
    Xei   = X;
  end;
  
  % pre-process the artifact signals as wanted
  if ( opts.center )       Xei = repop(Xei,'-',mean(Xei,dim(2))); end;
  if ( opts.detrend )      Xei = detrend(Xei,dim(2)); end;
  if ( ~isempty(artFilt) ) Xei = fftfilter(Xei,artFilt,[],dim(2),1); end % smooth the result  
  
                                       % compute the artifact covariance
  XXt  = tprod(Xei,tpIdx,[],tpIdx2); % cov of the artifact signal: [nArt x nArt]
                                % compute the time-lagged covariance
                                % First shift the data back in time
  XXtau = tprod(Xei,tpIdx,cat(dim(2),padding,Xei(idxtau{:})),tpIdx2); % WARNING: NOT SYMETRIC

                           % smooth the covariance filter estimates if wanted
  if( ~isempty(covFilt) )
    if( isnumeric(covFilt{1}) ) % move-ave
      filtstate.N     = alpha.*filtstate.N     + (1-alpha).*1;       % update weight
      filtstate.sxx   = alpha.*filtstate.sxx   + (1-alpha).*XXt;   % update move-ave
      filtstate.sxxtau= alpha.*filtstate.sxxtau+ (1-alpha).*XXtau; % update move-ave
                                % move-ave with warmup-protection
      XXt           = filtstate.sxx./N;   
      XXtau         = filtstate.sxxtau./N;
    else
      [XXt,filtstate]  =feval(covFilt{1},XXt,filtstate,covFilt{2:end});
      [XXtau,filtstate]=feval(covFilt{1},XXtau,filtstatetau,covFilt{2:end});
    end
  end    
  
  % Now we've got the (lagged)-covariances, compute the spatial-filters
                                % 1) Compute robust whitening transformation
  [Us,Ds]=eig(XXt);Ds=diag(Ds);
  keeps=~(isinf(Ds) | isnan(Ds) | abs(Ds)<max(Ds)*opts.tol | Ds<opts.tol);
  R=1./sqrt(abs(Ds));
  W = repop(Us(:,keeps),'*',(1./sqrt(Ds(keeps)))'); % whitening matrix
  iW= repop(Us(:,keeps),'*',sqrt(Ds(keeps))')';      % inverse whitening matrix, such that iW'*W'=I_d
                          %2) Compute the spatial-filters and emg-ness scores
  XXtau  = (XXtau + XXtau')/2; % ensure is symetric
  WXXtauW= W'*XXtau*W;
  [Ue,De]=eig(WXXtauW);De=diag(De);
                                %3) Identify the most EMG(ish) components,
                                %either small value or small rel to rest
  keepe=~(isinf(De) | isnan(De) | abs(De)<max(abs(De))*opts.tol); % valid eigs
  mude = mean(abs(De(keepe))); stdde=std(abs(De(keepe)));
  keepe= keepe & (abs(De)<=opts.minCorr | abs(De)<=mude-opts.corrStdThresh*stdde);
                                %4) Compute the emg-removal spatial filter
  if( nargout>2 ) Wemg(:,1:sum(keepe),epi) = W*Ue(:,keepe); end % filter to estimate the emg-channels
  Wall = W*(eye(size(Ue,1))-Ue(:,keepe)*Ue(:,keepe)')*iW;
  if( opts.verb>2 ) fprintf('%d) %d wht-comp, %d emg-comp\n',epi,sum(keeps),sum(keepe));end;
                                % the final spatial filter
  sf=Wall;
                                % apply the filter to the data
  if( nEp>1 ) % per-epoch mode, update in-place
    X(xidx{:}) = tprod(sf,[-dim(1) dim(1)],Xei,[1:dim(1)-1 -dim(1) dim(1)+1:ndims(X)]);    
  else % global regression mode
    X = tprod(sf,[-dim(1) dim(1)],X,[1:dim(1)-1 -dim(1) dim(1)+1:ndims(X)]);
  end
end
if ( opts.verb>=0 && nEp>10 ) fprintf('\n'); end;

% update the filter state
state         =opts;
state.R       =sf;
state.dim     =dim;
state.artFilt =artFilt;
state.covFilt =covFilt;
state.filtstate=filtstate;
state.filtstatetau=filtstatetau;

if(nargout>2) info = struct('Wemg',Wemg); end;
return;
%--------------------------------------------------------------------------
function testCase()
nSrc=10; nNoise=2; nCh=10; nSamp=1000; nEp=1000;
S=cumsum(randn(nSrc,nSamp,nEp),2); S=repop(S,'-',mean(S,2)); % sources with roughly 1/f spectrum
S(1:nNoise,:,:)=randn(nNoise,nSamp,nEp); %noise sources with flat spectrum
S=repop(S,'./',sqrt(sum(S(:,:).^2,2))); % unit-power signals

                                % signal forward model
A=eye(nSrc,nCh); % 1-1 mapping
A=randn(nSrc,nCh); % random sources [ M x d ]
% spatially smeared but centered sources
a=mkSig(nCh,'gaus',nCh/2,nCh/4);[ans,mi]=max(a);a=a([mi:end 1:mi-1]);A=zeros(nSrc,nCh);for i=1:size(A,1);A(i,:)=circshift(a,i-1);end; 
                                % data construction
X =reshape(A'*S(:,:),[nCh,nSamp,nEp]); % source+propogaged noise

[Y0,info] =rmEMG2(X,1); % single set of emg-filters for all time
[Y,info] =rmEMGFilt(X,[],1); % single set of emg-filters for all time
mad(Y0,Y)
[Y0,info] =rmEMG2(X); % adaptive filter over time
[Y,info] =rmEMGFilt(X,[]); % adaptive filter over time
[Y,info] =rmEMGFilt(X,[],[],'covFilt',10); % adaptive filter over time, cov-smoothing

% incremental calling
                                % incremental regress per-epoch
Yi=zeros(size(X));
[Yi(:,:,1),state]=rmEMGFilt(X(:,:,1),[],[1 2 3]);
for epi=2:size(X,3);
  textprogressbar(epi,size(X,3));
  [Yi(:,:,epi),state]=rmEMGFilt(X(:,:,epi),state);
end
mad(Y,Yi)

% plot the cross-correlations
clf;
SS=S(:,:);SS=repop(SS,'./',sqrt(sum(SS.*SS,2)));XX=X(:,:);XX=repop(XX,'./',sqrt(sum(XX.*XX,2)));YY=Y(:,:);YY=repop(YY,'./',sqrt(sum(YY.*YY,2)));
subplot(331);imagesc(SS*SS');title('SS^T'); subplot(332);imagesc(SS*XX');title('SX^T'); subplot(333);imagesc(SS*YY');title('SY^T');
subplot(334);imagesc(XX*SS');title('XS^T'); subplot(335);imagesc(XX*XX');title('XX^T'); subplot(336);imagesc(XX*YY');title('XY^T'); 
subplot(337);imagesc(YY*SS');title('YS^T'); subplot(338);imagesc(YY*XX');title('XY^T'); subplot(339);imagesc(YY*YY');title('YY^T');
set(findobj(gcf,'type','axes'),'clim',[-1.1 1.1]);colormap ikelvin;

                                % plot the found spatial filters
sf=info.sf; [U,S]=eig(sf); S=diag(S); Wemg=U(:,1:3);
Wemg=info.Wemg;
clf;mimage(A(:,1:nNoise),Wemg,'clim',[-1 1]);colormap ikelvin


