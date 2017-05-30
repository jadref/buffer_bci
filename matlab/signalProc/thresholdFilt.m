function [x,s]=thresholdFilt(x,s,thresh)
% simple thresholding filter, i.e. prediction only if bigger than threshold
%
%   [x,s,mu,std]=aveFilt(x,s,thresh)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   thresh - [float] prediction if norm(x)>thresh
% Outputs:
%   x - [nd x 1] filtered data
%   s - [struct] updated filter state
s=[];
if (norm(x)<thresh) x=[]; end;
return;
