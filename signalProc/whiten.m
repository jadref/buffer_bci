function [W,D,wX,U,mu,Sigma,alpha]=whiten(X,dim,alpha,centerp,stdp,symp,linMapMx,tol,unitCov,order)
% whiten the input data
%
% [W,D,wX,U,mu,Sigma,alpha]=whiten(X,dim[,alpha,center,stdp,symp,linMapMx,tol,unitCov,order])
% 
% N.B. this whitener leaves average signal power unchanged, but just de-correlates input channels
%
% Inputs:
%  X    - n-d input data set
%         OR
%         [nCh x nCh x n-d] set of data covariance matrices input-- only if dim(1)=0.
%  dim  - dim(1)=dimension to whiten, N.B. if dim(1)==0 then assume covariance matrices input
%         dim(2:end) whiten per each entry in these dim
%  alpha  - [float] regularisation parameter:                         (1) 
%           \Sigma' = (alpha)*\Sigma + (1-alpha) I * mean(diag(\Sigma))
%           0=no-whitening, 1=normal-whitening, 
%          'opt' = Optimal-Shrinkage est
%           alpha<0 -> 0=no-whitening, -1=normal-whitening, reg with alpha'th eigen-spectrum entry
%          'none' = don't regularise! just map to the eigen-directions
%  centerp- [bool] flag if we should center the data before whitening (1)
%  stdp   - [bool] flag if we should standardize input for numerical stability before whitening (0)
%  symp   - [bool] generate the symetric whitening transform (0)
%  linMapMx - [size(X,dim(2:end)) x size(X,dim(2:end))] linear mapping over non-acc dim 
%              use to smooth over these dimensions ([])
%           e.g. to use the average of 2 epochs to compute the covariance use:
%              linMapMx=spdiags(repmat([1 1]/2,size(X,dim(2)),1),[1 0],size(X,dim(2)),size(X,dim(2)))
%  tol  - [float] relative tolerance w.r.t. largest eigenvalue used to        (1e-6)
%                 reject eigen-values as being effectively 0. 
%           <0 >-1 : reject this percentage of the smallest eigenvalues
%           <-1    : keep only this number of eigenvalues
%  unitCov - [bool] make the covariance have unit norm for numerical accuracy (0)
%  order - [float] order of inverse to use (-.5)
% Outputs:
%  W    - [size(X,dim(1)) x nF x size(X,dim(2:end))] 
%          whitening matrix which maps from dim(1) to its whitened version
%          with number of factors nF
%       N.B. whitening matrix: W = U*diag(D.^order); 
%            and inverse whitening matrix: W^-1 = U*diag(D.^-order);
%  D    - [nF x size(X,dim(2:end))] orginal eigenvalues for each coefficient
%  wX   - [size(X)] the whitened version of X
%  U    - [size(X,dim(1)) x nF x size(X,dim(2:end))] 
%          eigen-decomp of the inputs
%  Sigma- [size(X,dim(1)) size(X,dim(1)) x size(X,dim(2:end))] the
%         covariance matrices for dim(1) for each dim(2:end)
%  mu   - [size(X) with dim(2:end)==1] mean to center everything else
if ( nargin < 3 || isempty(alpha) ) alpha=1; elseif(isnumeric(alpha)) alpha=sign(alpha)*min(1,max(abs(alpha),0)); end;
if ( nargin < 4 || isempty(centerp) ) centerp=1; end;
if ( nargin < 5 || isempty(stdp) ) stdp=0; end;
if ( nargin < 6 || isempty(symp) ) symp=0; end;
if ( nargin < 7 ) linMapMx=[]; end;
if ( nargin < 8 || isempty(tol) ) % set the tolerance
   if ( isa(X,'single') ) tol=1e-6; else tol=1e-9; end;
end
if ( nargin < 9 || isempty(unitCov) ) unitCov=1; end; % improve condition number before inversion
if ( nargin < 10 || isempty(order) ) order=-.5; end;

dim(dim<0)=dim(dim<0)+ndims(X)+1;
if( dim(1)==0 ) covIn=true; dim(1)=1; else covIn=false; end;

szX=size(X); szX(end+1:max(dim))=1; % pad with unit dims as necessary
if ( covIn ) 
  accDims=setdiff(1:ndims(X),[2 dim(:)']); % set the dims we should accumulate over
else
  accDims=setdiff(1:ndims(X),dim); % set the dims we should accumulate over
end
N    = prod(szX(accDims));

if ( covIn ) % covariance matrices input
  Sigma=X; for d=1:numel(accDims) Sigma=sum(Sigma,accDims(d)); end; Sigma=Sigma./N;
  sX   = [];
else
  % covariance + eigenvalue method
  idx1 = -(1:ndims(X)); idx1(dim)=[1 1+(2:numel(dim))]; % skip for OP dim
  idx2 = -(1:ndims(X)); idx2(dim)=[2 1+(2:numel(dim))]; % skip for OP dim   
  if ( isreal(X) ) % work with complex inputs
    XX = tprod(X,idx1,[],idx2,'n');%[szX(dim(1)) szX(dim(1)) x szX(dim(2:end))]
  else
    XX = tprod(real(X),idx1,[],idx2,'n') + tprod(imag(X),idx1,[],idx2,'n');
  end

  if ( centerp ) % centered
    sX   = msum(X,accDims);                              % size(X)\dim
    sXsX = tprod(double(real(sX)),idx1,[],idx2,'n');
    if( ~isreal(sX) ) sXsX = sXsX + tprod(double(imag(sX)),idx1,[],idx2,'n'); end
    Sigma= (double(XX) - sXsX/N)/N; 
    
  else % uncentered
    sX=[];
    Sigma= double(XX)/N;
  end
  clear XX;

  if ( stdp ) % standardise the channels before whitening
    X2   = tprod(real(X),idx1,[],idx1,'n');     % var each entry
    if( isreal(X) ) X2 = X2 + tprod(imag(X),idx1,[],idx1,'n'); end
    if ( centerp ) % include the centering correction
      sX2  = tprod(real(sX),idx1,[],idx1,'n');    % var mean
      if ( ~isreal(X) ) sX2=sX2 + tprod(imag(sX),idx1,[],idx1,'n'); end
      varX  = (double(X2) - sX2/N)/N; % channel variance                
    else      
      varX  = X2./N;
    end
    istdX = 1./sqrt(max(varX,eps)); % inverse stdX
                                    % pre+post mult to correct
    szstdX=size(istdX);
    Sigma = repop(istdX,'*',repop(Sigma,'*',reshape(istdX,[szstdX(2) szstdX([1 3:end])]))); 
  end
end
   
if ( ~isempty(linMapMx) ) % smooth the covariance estimates
  if ( numel(dim)>2 ) error('Not supported yet!'); end;
  if ( size(linMapMx,1)==1 ) 
    nrm=sum(linMapMx);
    linMapMx=spdiags(repmat(linMapMx,szX(dim(2)),1),numel(linMapMx)-1:-1:0,szX(dim(2)),szX(dim(2)));
    linMapMx=repop(full(linMapMx),'.*',nrm./sum(linMapMx,1)); % equal weight for all offsets
  end
  Sigma=tprod(Sigma,[1 2 -(3:ndims(Sigma))],full(linMapMx),[-(3:ndims(Sigma)) 3:ndims(Sigma)]);
end

% give the covariance matrix unit norm to improve numerical accuracy
if ( unitCov )  
  unitCov=median(diag(sum(Sigma,3)./size(Sigma,3))); Sigma=Sigma./unitCov; 
end;

W=zeros(size(Sigma),class(X));
if(numel(dim)>1) Dsz=[szX(dim(1)) szX(dim(2:end))];else Dsz=[szX(dim(1)) 1];end
D=zeros(Dsz,class(X));
nF=0;
for dd=1:size(Sigma(:,:,:),3); % for each dir
  Xdd=X; sXdd=sX;
   [Udd,Ddd]=eig(Sigma(:,:,dd)); Ddd=diag(Ddd); 
   [ans,si]=sort(abs(Ddd),'descend'); Ddd=Ddd(si); Udd=Udd(:,si); % dec abs order
   % compute the regularised eigen-spectrum
   if ( ischar(alpha) )     
     switch (alpha);
      case 'opt'; % optimal shrinkage regularisation estimate
       if ( numel(dim)>1 )
         if ( dim(2)~=3 ) error('Opt shrink only supported for dim=[1 3]'); end;
         Xdd=X(:,:,dd); if ( ~isempty(sX) ) sXdd=sX(:,:,dd); else sXdd=[]; end
       end       
       if ( unitCov ) 
          alphaopt=optShrinkage(Xdd,dim(1),Sigma(:,:,dd)*unitCov,sum(sXdd,2)./N,centerp); 
       else
          alphaopt=optShrinkage(Xdd,dim(1),Sigma(:,:,dd),sum(sXdd,2)./N,centerp); 
       end
       alphaopt=max(0,min(1,alphaopt));
       alphaopt=1-alphaopt; % invert type of alpha to be strength of whitening
       %error('not fixed yet!');
       %fprintf('%d) alpha=%g\n',dd,alphaopt);
       rDdd = alphaopt*Ddd + (1-alphaopt)*mean(Ddd);
      case 'none';
       rDdd = ones(size(Ddd));
      otherwise; error('Unrec alpha type');
     end
   elseif( alpha>=0 ) % regularise the covariance
     rDdd = alpha*Ddd + (1-alpha)*mean(Ddd); % absolute factor to add
   elseif ( alpha<0 ) % percentage of spectrum to use
     %s = exp(log(Ddd(1))*(1+alpha)+(-alpha)*log(Ddd(end)));%1-s(round(numel(s)*alpha))./sum(s); % strength is % to leave
     t = Ddd(round(-alpha*numel(Ddd))); % strength we want
     rDdd = (Ddd + t)*sum(Ddd)./(sum(Ddd)+t);
   end
   % only eig sufficiently big are selected
   si=true(numel(rDdd),1);
   if ( tol>0 )
     si=rDdd>max(abs(rDdd))*tol; % remove small and negative eigenvalues
   elseif ( tol>=-1 ) % percentage to reject
     si(floor(end*(1+tol))+1:end)=false;
   elseif( tol<-1 ) % number to reject
     si(end-(-tol)+1:end)=false;
   end
   if ( ~any(si) ) continue; end;
   % Now we've got a regularised spectrum compute it's inverse square-root to get a whitener
   iDdd=ones(size(Ddd),class(Ddd)); 
   if( order==-.5 ) iDdd(si) = 1./sqrt(rDdd(si)); else iDdd(si)=power(rDdd(si),order); end;
   % Use the principle-directions mapping and the re-scaling operator to compute the desired whitener
   
   if ( symp ) % symetric whiten
      W(:,:,dd) = repop(Udd(:,si),'*',iDdd(si)')*Udd(:,si)';
      nF=size(W,1);
   else % non-symetric
      W(:,1:sum(si),dd) = repop(Udd(:,si),'*',iDdd(si)');         
      nF = max(nF,sum(si)); % record the max number of factors actually used
   end
   U(:,1:sum(si),dd) = Udd(:,si);
   D(1:sum(si),dd)   = Ddd(si);
end
% Only keep the max nF
W=reshape(W(:,1:nF,:),[szX(dim(1)) nF szX(dim(2:end)) 1]);
D=reshape(D(1:nF,:),[nF szX(dim(2:end)) 1]);

% undo the effects of the standardisation
if ( stdp && dim(1)~=0 ) W=repop(W,'*',istdX); end

% undo numerical re-scaling
if ( unitCov ) W=W./sqrt(unitCov); D=D.*unitCov; end

if ( nargout>2 ) % compute the whitened output if wanted
  if ( covIn ) % covariance input
    idx1 = 1:ndims(X); idx1(1)=-1; 
    wX = tprod(X, idx1,W,[-1 1 dim(2:end)]); % apply whitening, pre
    idx1 = 1:ndims(X); idx1(2)=-2;
    wX = tprod(wX,idx1,W,[-2 2 dim(2:end)]); % apply whitening, post
  else
    if (centerp)   wX = repop(X,'-',sX./N); else wX=X; end % center the data
    % N.B. would be nice to use the sparsity of W to speed this up
    idx1 = 1:ndims(X); idx1(dim(1))=-dim(1); 
    wX = tprod(wX,idx1,W,[-dim(1) dim(1) dim(2:end)]); % apply whitening
  end
end
if ( nargout>3 && centerp && ~covIn ) mu=sX/N; else mu=[]; end;
return;
%------------------------------------------------------
function testCase()
z=jf_mksfToy();
clf;image3ddi(z.X,z.di,1,'colorbar','nw','ticklabs','sw');packplots('sizes','equal');

[W,D,wX,U,mu,Sigma]=whiten(z.X,1);
imagesc(wX(:,:)*wX(:,:)'./size(wX(:,:),2)); % plot output covariance

[W,D,wX,U,mu,Sigma]=whiten(z.X,1,'opt'); % opt-shrinkage

% with whiten for each example
[W,D,wX,U,mu,Sigma]=whiten(z.X,[1 3],1); 

% with opt and per-example whiten
[W,D,wX,U,mu,Sigma]=whiten(z.X,[1 3],'opt');

% with weighted whitent for each example
% wght averages with previous cov-mx
N=2; wght=spdiags(repmat(ones(1,N)/N,size(z.X,3),1),N-1:-1:0,size(z.X,3),size(z.X,3));
[W,D,wX,U,mu,Sigma]=whiten(z.X,[1 3],1,[],[],[],wght); 
[W,D,wX,U,mu,Sigma]=whiten(z.X,[1 3],1,[],[],[],ones(1,N)/N); 

clf;image3d(W,2)
N=4;wght=spdiags(repmat(ones(1,N)/N,size(z.X,3),1),N-1:-1:0,size(z.X,3),size(z.X,3));
[W,D,wX,U,mu,Sigma]=whiten(z.X,[1 3],1,[],[],[],wght); 
clf;image3d(W,2)

% test with covariance matrices as input
C=tprod(z.X,[1 -2 3],[],[2 -2 3])./size(z.X,2);
[Wc,Dc]=whiten(C,0);


% check that the std-code works
A=randn(11,10);  A(1,:)=A(1,:)*1000;  % spatial filter with lin dependence
sX=randn(10,1000); sC=sX*sX'; [sU,sD]=eig(sC); sD=diag(sD); wsU=repop(sU,'./',sqrt(sD)'); 
X=A*sX; C=X*X';    [U,D]=eig(C);     D=diag(D);   wU=repop(U,'./',sqrt(D)'); 
mimage(wU'*C*wU,wsU'*sC*wsU)
mimage(repop(1./d,'*',wsU)'*C*repop(1./d,'*',wsU))
[W,D,wX,Sigma]=whiten(X,1,0,0);
[sW,sD,swX,sSigma]=whiten(X,1,0,1);
