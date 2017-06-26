function [X,state]=carFilt(X,state);
% filter function implementing common average reference
if( nargin<2 ) state=[]; end;
if( isempty(state) ) state.R = eye(size(X,1))-(1./size(X,1)); end;
X=tprod(X,[-1 2 3],R,[1 -1]);
return;
  
