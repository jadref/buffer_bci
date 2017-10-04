function [X,state]=splineCARFilt(X,state,varargin);
% filter function implementing the spherical-spline based - infinite reference approximation
if( nargin<2 ) state=[]; end;
if( isempty(state) ) % pre-compute the spatial filter to use
   opts=struct('ch_pos',[],'ch_names',[],'fs',[]);
   opts=parseOpts(opts,varargin);
   R=sphericalSplineInterpolate(opts.ch_pos,opts.ch_pos,[],[],'splineCAR');
   state.R = R; 
end;
X=tprod(X,[-1 2 3],R,[1 -1]);
return;
  
