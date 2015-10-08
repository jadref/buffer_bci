function [x]=mmean(x,dims);
% multi-dimensional mean
sz=size(x);
[x,dims]=msum(x,dims);  % just a wrapper arround msum
x=x./prod(sz(dims));
return;
%-----------------------------------------------------------------
function testCase()
