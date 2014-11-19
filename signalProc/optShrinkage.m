function [lambda,Sigma,muX]=optShrinkage(X,dim,Sigma,muX,centerp)
% optimal shrinkage estimation for covariance matrix estimation
%
% [lambda,Sigma,muX]=optShrinkage(X,dim,Sigma,muX,centerp)
%
%  \Sigma_opt = (1-\lambda)*\Sigma + \lambda*I*mean(diag(Sigma))
%
% Inputs:
%  X  - [n-d] inputs
%  dim - dimension(s) of X which contain the channels
%  Sigma - pre-computed channel covariance matrix
%  muX   - pre-computed channel mean
%  centerp - [bool] center the data (1)
if ( nargin<2 || isempty(dim) ) dim=find(size(X)>1,1); if(isempty(dim))dim=1;end; end;
if ( nargin<3 ) Sigma=[]; end
if ( nargin<4 ) muX=[]; end;
if ( nargin<5 || isempty(centerp) ) centerp=1; end
szX=size(X); 
if ( ndims(X)>2 )
  if ( all(dim(:)'==1:numel(dim)) ) X=reshape(X,prod(szX(dim)),[]); dim=1; 
  elseif ( all(dim(:)'==ndims(X)+1-(numel(dim):-1:1)) ) X=reshape(X,[],prod(szX(dim))); dim=2;
  else error('Only 1st/last dim supported');
  end
end
szX=size(X); 
rdim=setdiff(1:ndims(X),dim);
N=prod(szX(rdim));
if ( isempty(Sigma) )
   if(dim==1) Sigma=X*X'/N;  elseif (dim==2) Sigma=X'*X./N; else error('Only 2d inputs'); end;   
end
if ( centerp && isempty(muX) )   
   muX  =msum(X,rdim)./N;
   Sigma=Sigma-muX(:)*muX(:)'; 
end

mu=sum(Sigma(1:size(Sigma,1)+1:end))./size(Sigma,1); %mu=<I,Sigma>, proj to sphere
nSigma=Sigma(:)'*Sigma(:);
alpha2=nSigma-mu*mu*size(Sigma,1); %alpha^2=|muI-Sigma|_F^2, error to sphere
% alpha2=Sigma-eye(size(Sigma,1))*mu; alpha2=alpha2(:)'*alpha2(:); %direct comp test
%X2=msum(X.*X,dim); % ave length^2 of each input
idx=1:ndims(X); idx(dim)=-dim; X2=tprod(X,idx,[],idx); % mem efficient computation
if (centerp) %beta^2=E(|S-\Sigma|_F^2)~=1/N^2 \sum_i(|x_ix_i' - Sigma|_F^2), expected error to sample estimate
   idx=1:ndims(X); idx(dim)=-dim; XmuX=tprod(X,idx,muX(:),-dim,'n');
   beta2=(sum((X2(:)-2*XmuX(:)+muX(:)'*muX(:)).^2)/N-nSigma)/N;
else
   beta2=(sum(X2(:).^2)/N-nSigma)/N;
end
% delta = norm(sample-prior,'fro')^2;

% direct computation of beta, for testing
%beta2=0; for i=1:prod(szX(2:end));b2i=X(:,i)*X(:,i)'-Sigma; b2i=b2i(:)'*b2i(:); beta2=beta2+b2i; end; beta2=beta2/N/N;

lambda=beta2./(beta2+alpha2);
return
%----------------------
function testcase()
nd=100;
X=randn(nd,1000); Sigmas=eye(size(X,1));
l=4; s= exp(-(1:nd)'/(nd)*l);
X=repop(sqrt(s),'*',X); Sigmas=diag(s); %trans space

Ufwd=orth(randn(nd,nd)); % rotate/mix
X=Ufwd'*X; Sigmas=Ufwd'*Sigmas*Ufwd;

N=100;
for N=[100:100:1000];
  Sigma=X(:,1:N)*X(:,1:N)'./N;
  err=Sigma-Sigmas; err=err(:)'*err(:);
  os=optShrinkage(X(:,1:N)); os=os;
  oserr=Sigmas-(Sigma*(1-os)+eye(size(Sigma))*os*mean(diag(Sigma))); oserr=oserr(:)'*oserr(:);
  [S,sd]=shrinkDiag(X(:,1:N)'); 
  sderr=Sigmas-(Sigma*(1-sd)+eye(size(Sigma))*sd*mean(diag(Sigma))); sderr=sderr(:)'*sderr(:);
  fprintf('%4d) err=%9g\tos=%9g\tos_err=%9g\tsd=%9g\tsderr=%9g\n',N,err,os,oserr,sd,sderr);
end

%asympoic test
szX=size(X);
beta2=0;
for i=1:prod(szX(2:end));
   Sigman=X(:,1:i)*X(:,1:i)'/i;
   beta2=0;for j=1:i; b2i=X(:,j)*X(:,j)'-Sigman; b2i=b2i(:)'*b2i(:); beta2=beta2+b2i; end; beta2n(i)=beta2/i/i; 
   b2i=Sigman-Sigmas; b2i=b2i(:)'*b2i(:); beta2ns(i)=b2i;
end; 
clf;plot([beta2ns; beta2n]');legend('true error','est error')