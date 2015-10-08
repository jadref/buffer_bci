function [sf,d,Sigmac,SigmaAll]=csp(X,Y,dim,nf_cent,ridge,singThresh,powThresh)
% Generate spatial filters using CSP
%
% [sf,d,Sigmac,SigmaAll]=csp(X,Y,[dim,nfilt,ridge]);
% N.B. if inputs are singular then d will contain 0 eigenvalues & sf==0
% Inputs:
%  X     -- n-d data matrix, e.g. [nCh x nSamp x nTrials] data set, OR
%  Y     -- [nTrials x 1] set of trial labels, with nClass unique labels, OR
%           [nTrials x nClass] set of +/-1 (&0) trial lables per class, OR
%           N.B. in all cases a label of 0 indicates ignored trial
%  dim   -- [1 x 2] dimension of X which contains the trials, and
%           (optionally) the the one which contains the channels.  If
%           channel dim not given the next available dim is used. ([-1 1])
%  nfilt -- [1x1] number of filters to take from each class
%           [1xnClass] 
%  ridge -- [float] size of ridge (as fraction of mean eigenvalue) to add for numerical stability (1e-7)
% Outputs:
%  sf    -- [nCh x nCh x nClass] sets of 1-vs-rest spatial *filters*
%           sorted in order of increasing eigenvalue.
%           N.B. sf is normalised such that: mean_i sf'*cov(X_i)*sf = I
%           N.B. to obtain spatial *patterns* just use, sp = Sigma*sf ;
%  d     -- [nCh x nClass] spatial filter eigen values, N.B. d==0 indicates bad direction
if( nargin>4 ) 
  warning('extra options ignored'); 
  if ( nargin>3 && nfeat<=1 ) nfeat=[]; end; % reset to default number features
end;
if ( nargin < 3 || isempty(dim) ) dim=[-1 1]; end;
if ( numel(dim) < 2 ) if ( dim(1)==1 ) dim(2)=2; else dim(2)=1; end; end
dim(dim<0)=ndims(X)+dim(dim<0)+1; % convert negative dims
if ( nargin < 4 || isempty(nfeat) ) nfeat=3; end;
if ( nargin < 5 || isempty(ridge) ) 
  if ( isequal(class(X),'single') ) ridge=1e-7; else ridge=0; end;
end;
nCh = size(X,dim(2)); N=size(X,dim(1)); nSamp=prod(size(X))./nCh./N;

if ( ndims(Y)==2 && min(size(Y))==1 ) 
  oY=Y;
  Y=lab2ind(Y,[],[],[],0); 
end;
nClass=size(Y,2);

Xidx={}; for d=1:ndims(X); Xidx{d}=1:size(X,d); end; % index expression for X

% compute the global covariance
idx1=-(1:ndims(X)); idx2=-(1:ndims(X)); % sum out everything but ch, trials
idx1(dim(1))=-3;    idx2(dim(1))=-3;     % sum out trial dimension
idx1(dim(2))=1;     idx2(dim(2))=2;     % Outer product over ch dimension
Xidx{dim(1)}=~all(Y==0,2); % all except examples marked as ignored
Sigmaall = tprod(X(Xidx{:}),idx1,[],idx2)./sum(Xidx{dim(1)});

sf    = zeros([nCh,nfeat,nClass],class(X)); d=zeros(nfeat,nClass,class(X));
for c=1:nClass; % generate sf's for each sub-problem
  Xidx{dim(1)}=Y(:,c)>0;
  Sigmac(:,:,c) = tprod(X(Xidx{:}),idx1,[],idx2)./sum(Xidx{dim(1)});
  % solve the generalised eigenvalue problem, 
  if ( ridge>0 ) % Add ridge if wanted to help with numeric issues in the inv
    Sigmac(:,:,c)=Sigmac(:,:,c)+eye(size(Sigma))*ridge*mean(diag(Sigmac(:,:,c))); 
    Sigma        =Sigma        +eye(size(Sigma))*ridge*mean(diag(Sigma));
  end
  % N.B. use double to avoid rounding issues with the inv(Sigma) bit
  [W D]=eig(double(Sigmac(:,:,c)),double(Sigmaall));D=diag(D); % generalised eigen-value formulation!
  W=real(W); % only real part is useful
  [D,di]=sort(D,'descend'); W=W(:,di); % order in decreasing eigenvalue
   
  % Save the normalised filters & eigenvalues
  sf(:,:,c)= W(:,1:nfeat);  
  d(:,c)   = D(1:nfeat);
end
return;

function []=testCase()
nCh = 64; nSamp = 100; N=300;
X=randn(nCh,nSamp,N);
Y=sign(randn(N,1));
[sf,d,Sigmac,Sigmaall]=csp(X,Y);
