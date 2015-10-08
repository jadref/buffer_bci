function [x,s]=aveFilt(x,s,len)
% Windowed average filter
%
%   [x,s,mu,std]=aveFilt(x,s,len)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   len - [int] number of past samples to include in the average
% Outputs:
%   x - [nd x 1] filtered data
%   s - [struct] updated filter state
if ( isempty(s) ) s=struct('buff',zeros(size(x,1),len),'i',0); end;
s.i=mod(s.i,len)+1;
s.buf(:,s.i)=x;
x=mean(s.buf,2);
return;
function testCase()
x=cumsum(randn(1,1000));
s=[]; for i=1:numel(x); [fx(i),s]=aveFilt(x(:,i),s,10); end;
s=[]; for i=1:numel(x); [fx(i),s]=aveFilt(x(:,i),s,100); end;