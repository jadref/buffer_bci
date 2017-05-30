function [x,s]=avenFilt(x,s,len)
% only send an average prediction output very n'th output
%
%   [x,s,mu,std]=avenFilt(x,s,len)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   len - [int] number of past samples to include in the average
% Outputs:
%   x - [nd x 1] filtered data
%   s - [struct] updated filter state
if ( isempty(s) ) s=struct('x',zeros(size(x,1),1),'i',0); end;
s.i=s.i+1;
s.x=s.x+x;
if( s.i>=len )
  x = s.x./s.i;
  % clear internal state
  s.x(:)=0;
  s.i   =0;
else
  x = []; % don't send
end
return;
function testCase()
x=randn(4,1000);
s=[]; for i=1:size(x,2); [fx{i},s]=avenFilt(x(:,i),s,3); end;
s=[]; for i=1:size(x,2); [fx{i},s]=avenFilt(x(:,i),s,10); end;
