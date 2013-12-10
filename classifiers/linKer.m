function K=linKer(X,Z,dim)
% Compute linear kernel using tprod
%
% K=linKer(X,Z,dim)
%
% Inputs:
% X   -- n-d data matrix with N1 examples
% Y   -- n-d data matrix with N2 examples
% dim -- which dimension along which the examples lie. 
%        (N.B. negative dims index from the last dimension)
%        1  -> trials in the first dimension, i.e.X= [N x ... ]
%        -1 -> trials in the last dimension, i.e. X= [... x N ]
% Outputs
% K   -- [N1 x N2] linear kernel matrix
%
% Copyright 2006-     by Jason D.R. Farquhar (jdrf@zepler.org)

% Permission is granted for anyone to copy, use, or modify this
% software and accompanying documents for any uncommercial
% purposes, provided this copyright notice is retained, and note is
% made of any changes that have been made. This software and
% documents are distributed without any warranty, express or
% implied

if ( nargin < 2 ) Z=X; end;
if ( nargin < 3  || isempty(dim) ) dim=1; end;
dim(dim<0)=dim(dim<0)+ndims(X)+1; 

% Compute the appropriate indexing expressions
idx  =-(1:ndims(X)); idx(dim)=1:numel(dim);               % normal index
tidx =-(1:ndims(X)); tidx(dim)=numel(dim)+(1:numel(dim)); % transposed index

K=tprod(X,idx,Z,tidx,'n');
% reshape to square matrix of wanted
%if ( numel(dim)>1 ) szK=size(K); K=reshape(K,prod(szK(1:numel(dim))),prod(szK(numel(dim)+1:end))); end;
return;

%-------------------------------------------------------------------------
function testCase()
X=randn(100,100);
K1=linKer(X,[],1);  K11=X*X'; max(abs(K1(:)-K11(:)))
K2=linKer(X,[],2);  K21=X'*X; max(abs(K2(:)-K21(:)))
K3=linKer(X,[],-1); max(abs(K2(:)-K3(:)))
mimage(K1,K11,K2,K21,K3);
