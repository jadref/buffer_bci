function [r]=mad(X,Y);
if ( nargin < 2 ) ; Y=0; end;
r=max(abs(X(:)-Y(:)));
