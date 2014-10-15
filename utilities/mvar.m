function [v,mu]=mvar(x,dims);
% multi-dimensional variance computation
%
% [v]=mvar(x,dims);
% Inputs:
%  x    -- n-d matrix
%  dims -- set of dimensions of x to sum along to compute the variance
% Outputs:
%  v    -- variances
%  mu   -- means
sz=size(x);
[sX,dims]=msum(x,dims);
if ( ~isreal(sX) ) sX=abs(sX); end;
idx =1:ndims(x); idx(dims)=-idx(dims); % compute tprod calling info
if ( isreal(x) ) sX2=tprod(x,idx,[],idx); % compute the sum x.^2
else             sX2=tprod(real(x),idx,[],idx)+tprod(imag(x),idx,[],idx);
end
N        =prod(sz(dims));
v        =sX2/N - sX.^2/N.^2; % var = ( \sum_i x_i^2 - (\sum_i x_i)^2/N ) / N
v        =max(0,v); % threshold at 0 for numerical issues
if ( nargout>1 ) mu=sX./N; end;
return;
%-------------------------------------------------------------------------
function testCase()