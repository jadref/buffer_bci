function [X,state]=xchRegress(X,state,varargin)
% cross-channel regress out any signal correlated with the input signals from the data
% 
%   [X,state]=xartChRegress(X,state,....)
%
% Inputs:
%  X   -- [n-d] the data to be deflated/art channel removed
% Options:
%  dim -- dim(1) = the dimension along which to correlate/deflate ([1 2])
%         dim(2) = the time dimension for spectral filtering/detrending along
%         dim(3) = compute regression separately for each element on this dimension
%  xchInd -- [size(X,dim(1)),size(X,dim(1)) bool] indicator set for each output channel of
%           the set of input channels it should decorrelate with
%         OR
%            [size(X,dim(1)),M,size(X,dim(1)) float] set of spatial-filters to use to compute the
%              set of channels to de-correlate with for each output channel
%  bands   -- spectral filter (as for fftfilter) to apply to the artifact signal ([])
%  fs  -- the sampling rate of this data for the time dimension ([])
%         N.B. fs is only needed if you are using a spectral filter, i.e. bands.
%  detrend -- detrend the artifact before removal                        (1)
%  center  -- center in time (0-mean) the artifact signal before removal (0)
%  covFilt -- {str} function to apply to the computed covariances to smooth them prior to regression {''}
%              SEE: biasFilt for example function format
%            OR
%             [float] half-life to use for simple exp-moving average filter
%  filtstate -- [struct] previous state for the covariance filter function to use over calls..
if( nargin<2 ) state=[]; end;
if( ~isempty(state) && isstruct(state) ) % ignore other arguments if state is given
  opts =state;
  artFilt=state.artFilt;
else
  opts=struct('xchInd',[],'center',0,'detrend',0,'bands',[],'covFilt','','filtstate','','verb',1,...
              'dim',[1 2 3],'ch_names','','ch_pos',[],'fs',[],'tol',1e-8,'evwarn',.9);
  [opts]=parseOpts(opts,varargin);
  artFilt=[];
end
dim=opts.dim; dim(dim<0)=ndims(X)+1+dim(dim<0);
szX=size(X); szX(end+1:max(dim))=1;
if( numel(dim)<3 ) nEp=1; else nEp=szX(dim(3)); end;

% get the set of input channels to regress for each output channel
xchInd=opts.xchInd;
if( ~isnumeric(xchInd) || ~(ndims(xchInd)==2 && size(xchInd,1)==size(X,dim(1)) && size(xchInd,1)==size(xchInd,2) ) )
  if( isnumeric(xchInd) )    
    if ( numel(xchInd)==2 && all(xchInd>=-1 & xchInd<=1) ) % 2-elements all in [-1 1] => angle-range to use
      if( ~isempty(opts.ch_pos) )
        src  = opts.ch_pos;
        src  = repop(src,'./',sqrt(sum(src.^2)));      % map to the sphere
        cosSS= src'*src;                               % compute the relative angles
        xchInd=cosSS>min(xchInd) & cosSS<max(xchInd);  % apply the thresholds
      else
        error('Cant use angle-range without electrode positions...');
      end

    % numeric-row-vector => set of same channels to remove from every output channel
    elseif ( sum(size(xchInd)>1)==1 && (numel(xchInd)~=size(X,dim(1)) || size(xchInd,1)==1) ) 
      tmp=xchInd; xchInd=false(size(X,dim(1))); xchInd(tmp,:)=true;
    end
  end
end
  
% setup the spectral filter if needed
if ( isempty(artFilt) && ~isempty(opts.bands) ) % smoothing filter applied to art-sig before we use it
  if( isempty(opts.fs) ) warning('Sampling rate not specified.... using default=100Hz'); opts.fs=100; end;
  artFilt = mkFilter(floor(szX(dim(2))./2),opts.bands,opts.fs/szX(dim(2)));
end

% set-up the covariance filtering function
covFilt=opts.covFilt; filtstate=opts.filtstate; 
if( ~isempty(covFilt) )
  if( ~iscell(covFilt) ) covFilt={covFilt}; end;
  if( isnumeric(covFilt{1}) ) % covFilt{1} is alpha for move-ave
    if(covFilt{1}>=1) covFilt{1}=exp(log(.5)./covFilt{1}); end; % convert half-life to alpha
    if(isempty(filtstate) )    filtstate=struct('N',0,'sxx',0);    end;
  end
end

% N.B. index expressions with int32 or bool types are **much** faster (particularly on Octave)
% make a index expression to extract the current epoch.
xidx  ={}; for di=1:numel(szX); xidx{di}=int32(1:szX(di)); end;

                % tprod-arguments for computing the channel-covariance matrix
tpIdx  = -(1:ndims(X)); tpIdx(dim(1)) =1; 
tpIdx2 = -(1:ndims(X)); tpIdx2(dim(1))=2; 


% N.B. this incremental version is 2x slower than the pre-compute in blocks version....
sf=[]; nWht=zeros(1,nEp); nEmg=zeros(1,nEp);
if ( opts.verb>=0 && size(X,dim(1)).*nEp>10 ) fprintf('xchRegress:'); end;
for epi=1:nEp; % loop over epochs
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

                           % smooth the covariance filter estimates if wanted
  if( ~isempty(covFilt) )
    if( isnumeric(covFilt{1}) ) % move-ave
      alpha           = covFilt{1};
      alpha           = alpha.^size(Xei,dim(2)); % specified in data-packets
      filtstate.N     = alpha.*filtstate.N     + (1-alpha).*1;       % update weight
      filtstate.sxx   = alpha.*filtstate.sxx   + (1-alpha).*XXt;   % update move-ave
                                % move-ave with warmup-protection
      XXt           = filtstate.sxx./filtstate.N;   
    else
      [XXt,filtstate]  =feval(covFilt{1},XXt,filtstate,covFilt{2:end});
    end
  end    
  
  % now loop over channels deflating w.r.t. the other channels
  for ci=1:size(X,dim(1)); % TODO: group outputs with same art-ch to save computation?
    if( opts.verb>0 && size(X,dim(1)).*nEp>10 ) textprogressbar(epi*size(X,dim(1))+ci,nEp*size(X,dim(1))); end

     % extract the artifact channel info for this output channel
    if ( islogical(xchInd) )% special case sub-set of channels are artifact channels    
      artCh=xchInd(:,ci)>0; nArt=sum(artCh);
      if( nArt==0 ) continue; end;
                                % compute the inverse artifact covariance
      Ici = zeros(size(X,1),1); Ici(ci)=1; 
      % Delfation w.r.t. the constraints part
      BXXtB  = XXt(artCh,artCh);
% TODO: sub-select channels to use to avoid using too highly correlated artifact channels...
      % [artCov(:,ci,epi)./sqrt(diag(artCov(:,:,epi)).*artCov(ci,ci,epi)) xchInd(:,ci)>0] % est-cross-corr
      BXYt   = XXt(artCh,ci);          % [nArt x 1]  artifact target product (B^TXY^T)
% regression solution for estimateing X from the artifact channels: w_B = (B^TXX^TB)^{-1} B^TXY^T = (BX)\Y
%w_B    = BXXtB\BXYt; % fast, sparse -- BUT, not robust to rank-deficient inputs
      w_B    = pinv(BXXtB)*BXYt; % slower, min-norm, low-rank robust(ish) [nArt x 1]
% estimate the residual after this fit: SSE=Y^2-2*wXY^T+w^TXX^Tw = Y^2-2((XXt)^{-1}XY)^T
% sse = YY' - 2w'XY' + w'XX'w = YY' - ((XX')^{-1}XY')'XY' + ((XX')^{-1}XY')XX'(XX')^{-1}XY'
%     = YY' - 2YX'(XX')^-1XY' + YX'(XX')^-1XX'(XX')^-1XY' = YY' - 2YX'(XX')^-1XY' + YX'(XX')^-1XY'
%     = YY' - YX'(XX')^-1XY'
% 1-sse/(YY') = 1- 1 - YX'(XX')^-1XY'(YY')^-1 = YX'(XX')^{-1}XY'(YY')^-1 = explained variance
      ev = BXYt'*w_B./XXt(ci,ci);
      if( opts.evwarn>0 && ev>opts.evwarn ) 
        fprintf('Error: xchRegress::excessive variance explained: ch=%d epi=%d ev=%g\n',ci,epi,ev);
      end
 % make a single spatial filter to remove the artifact signal in 1 step
 % Y-w^TB^TX = Y-YX^TB (B^TXX^TB)^{-1} B^TX = Y(I- X^TB (B^TXX^TB)^{-1} B^TX)
%             iff Y==X -> X(I-X^TB (B^TXX^TB)^{-1} B^TX)=(I-XX^TB (B^TXX^TB)^{-1} B^T)X = (I-w_B^TB^T)X
% H=(I-w_B^TB^T)^T = I-Bw_B
      F = Ici; F(artCh)=F(artCh) - w_B;
      sf(:,ci) = F;
    else % set of spatial filters to apply
         % extract the spatial filters
      
      if( isnumeric(xchInd) && ndims(xchInd)>2 ) B=xchInd(:,:,ci); B(all(B==0,1))=[]; % set spatial filters to use
      elseif( iscell(xchInd) && numel(xchInd)==size(X,1) ) B=xchInd{ci}; % cell array sets spatial filters
      else B=xchInd;      
      end;
      if ( isempty(B) ) continue; end;
        
                                % compute the inverse artifact covariance
      w_B = zeros(size(B,2),1); % [nArt x 1]
      BXXt   = B'*XXt;
      iBXXtB = pinv(BXXt*B); % inverse-artifact-covariance (B^TXX^TB)^{-1}
      BXYt   = BXXt(:,ci);   % artifact target product (B^TXY^T)
% regression solution for estimateing X from the artifact channels: w_B = (B^TXX^TB)^{-1} B^TXY^T = (BX)\Y
      w_B    = iBXXtB*BXYt; % [nArt x 1]
      ev = BXYt'*w_B./XXt(ci,ci);
      if( opts.evwarn>0 && ev>opts.evwarn ) 
        fprintf('Error: xchRegress::excessive variance explained: ch=%d epi=%d ev=%g\n',ci,epi,ev);
      end
       % make a single spatial filter to remove the artifact signal in 1 step
       %  X-w^TB^TX = (I-w^TB^T)*X
       % w=(I-w_B^TB^T)^T = I-Bw_B = I - B (B^TXX^TB)^{-1} B^TX
      sf(:,ci)=sf(:,ci)-B*w_B;
    end
  end % loop over output channels
  
                                % apply the deflation
  if( nEp>1 ) % per-epoch mode, update in-place
    X(xidx{:}) = tprod(sf,[-dim(1) dim(1)],Xei,[1:dim(1)-1 -dim(1) dim(1)+1:ndims(X)]);    
  else % global regression mode
    X = tprod(sf,[-dim(1) dim(1)],X,[1:dim(1)-1 -dim(1) dim(1)+1:ndims(X)]);
  end  
end % loop over epochs
if( opts.verb>0 && size(X,dim(1)).*nEp>10 ) fprintf('\n'); end

% update the filter state
state         =opts;
state.R       =sf;
state.dim     =dim;
state.xchInd  =xchInd;
state.artFilt =artFilt;
state.covFilt =covFilt;
state.filtstate=filtstate;
return;
%--------------------------------------------------------------------------
function testCase()
nSrc=10; nNoise=2; nCh=10; nSamp=1000; nEp=1;
S=randn(nSrc,nSamp,nEp);% sources
                                % signal forward model
A=eye(size(S,1),nCh); % 1-1 mapping
A=randn(size(S,1),nCh); % random sources [ M x d ]
% spatially smeared but centered sources
a=mkSig(nCh,'gaus',nCh/2,nCh/8);[ans,mi]=max(a);a=a([mi:end 1:mi-1]);A=zeros(size(S,1),nCh);for i=1:size(A,1);A(i,:)=circshift(a,i-1);end; 
% noise additional forward model
B=zeros(size(S,1),nCh);
B(1:nNoise,:)=randn(nNoise,size(B,2)); % random noise
B(1:nNoise,:)=[1;-1]*randn(1,size(B,2)); % Noise is difference of 1st-2 channels
                                % data construction
X =reshape((A+B)'*S(:,:),[nCh,nSamp,nEp]); % source+propogaged noise

% Single spatial-filter for all time
Y0 =artChRegress(X,[],1,[1 2]);
[Y,state] =xchRegress(X,[],'dim',1,'xchInd',[1 2]); 
mad(Y,Y0)

% Adaptive spatial filter for each time point
Y0 =artChRegress(X,[],[1 2 3],[1 2]);
[Y,state] =xchRegress(X,[],'dim',[1 2 3],'xchInd',[1 2]); 
mad(Y,Y0)

                         % specify the per-output  removal set by angle range
ch_pos=randn(3,size(X,1));
[Y,state] =xchRegress(X,[],'dim',[1 2 3],'xchInd',[-.5 .5],'ch_pos',ch_pos); 


                                % incremental regress per-epoch
[Yi(:,:,1),state]=xchRegress(X(:,:,1),[],'dim',[1 2 3],'xchInd',[1 2]);
for epi=2:size(X,3);
  textprogressbar(epi,size(X,3));
  [Yi(:,:,epi),state]=xchRegress(X(:,:,epi),state);
end
mad(Y,Yi)



clf;
SS=S(:,:);SS=repop(SS,'./',sqrt(sum(SS.*SS,2)));XX=X(:,:);XX=repop(XX,'./',sqrt(sum(XX.*XX,2)));YY=Y(:,:);YY=repop(YY,'./',sqrt(sum(YY.*YY,2)));
subplot(331);imagesc(SS*SS');title('SS^T'); subplot(332);imagesc(SS*XX');title('SX^T'); subplot(333);imagesc(SS*YY');title('SY^T');
subplot(334);imagesc(XX*SS');title('XS^T'); subplot(335);imagesc(XX*XX');title('XX^T'); subplot(336);imagesc(XX*YY');title('XY^T'); 
subplot(337);imagesc(YY*SS');title('YS^T'); subplot(338);imagesc(YY*XX');title('XY^T'); subplot(339);imagesc(YY*YY');title('YY^T');
set(findobj(gcf,'type','axes'),'clim',[-1.1 1.1]);colormap ikelvin;

                                % per-channel art-ch
artCh={[2] [3] [4] [5] [6] [7] [8] [9] [1]};
B=false(size(X,1),size(X,1)); for ci=1:size(B,2); B(artCh{min(end,ci)},ci)=true; end;
[Y,info] =xchRegress(X,1,B); % single different art-ch for all outputs

                                % spatially-filtered-art-channels
B=zeros(size(X,1),2); B(1,1)=1; B(2,2)=1; % ch1 and ch2 - should be same as [1 2] and the same as artChRegress
B=zeros(size(X,1),1); B(1:2)=[-1 1]; % channel difference artifact channel
[Y,info] =xchRegress(X,1,B);


                                % regress per-epoch
[Y0,info]=artChRegress(X,[1 2 3],[1 2]);
[Y,info] =xchRegress(X,[1 2 3],[1 2]); % single set of art-ch for all outputs
[Y,info] =xchRegress(X,[1 2 3],[1 2],'covFilt',10); % hl=10 ma-filtered cov
mad(Y,Y0)
