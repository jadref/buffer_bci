function D = sqdist(X, Z, dim)
% D = sqdist(X, Z, dim) % Squared Euclidean distance.
% 
% Inputs:
% X   -- n-d input matrix of N points
% Z   -- n-d input matrix of M points, N.B. z=x if z isempty
% dim -- dimension along which the points lie (1, i.e. row vectors)
%        -1 -> trials in the last dimension (i.e. col-vectors)
%        (negative dim values index back from the last dimension)
% Outputs
% D   -- [N x M] squared distance matrix
% $Id: sqDist.m,v 1.4 2007-05-28 19:55:02 jdrf Exp $
if ( nargin < 2 ) Z = []; end
if ( nargin < 3 || isempty(dim) ) dim=1; end; % 
if ( dim < 0 ) dim=ndims(X)+dim+1; end;

% Compute the appropriate indexing expressions
idx  = -(1:ndims(X)); idx(dim)=1:numel(dim);               % normal index
tidx = -(1:ndims(X)); tidx(dim)=numel(dim)+(1:numel(dim)); % transposed index

% Do the actual computation
X2=tprod(X,[],idx,idx);
if ( isempty(Z) ) Z2=X2;
else Z2=tprod(Z,[],idx,idx);
end
XZ = tprod(X,Z,idx,tidx);
D=repop(repop(X2,'+',-2*XZ),'+',shiftdim(Z2,-numel(dim)));
return;

%-------------------------------------------------------------------------
function testCase()
X=randn(100,100);
D1=sqDist(X,[],1); % this way
D11=shiftdim(sum(repop(X','-',reshape(X',[100 1 100])).^2,1)); % explicit
D2=sqDist(X,[],2); 
D21=shiftdim(sum(repop(X,'-',reshape(X,[100 1 100])).^2,1));
mimage(D1,D11,D2,D21)