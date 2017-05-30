function [x,s]=marginFilt(x,s,margin)
% send event when accumulated margin between best and 2nd best prediction is greater than margin
%
%   [x,s]=marginFilt(x,s,margin)
%
% Inputs:
%   x - [nd x 1] the data to filter
%   s - [struct] internal state of the filter
%   margin - [float] minimum difference between best & 2nd best prediction
% Outputs:
%   x - [nd x 1] filtered data
%   s - [struct] updated filter state
if ( isempty(s) ) s=struct('x',zeros(size(x,1),1)); end;
s.x=s.x+x;
if( numel(s.x)>1 ) 
  sx=sort(s.x,'descend');
else % binary special case
  sx=2*abs(s.x);
end
if( sx(1)>=sx(2)+margin )
  x=s.x;
  % clear internal state
  s.x(:)=0;
else
  x = []; % don't send
end
return;
function testCase()
x=randn(4,1000);
s=[]; for i=1:size(x,2); [fx{i},s]=marginFilt(x(:,i),s,3); end;
s=[]; for i=1:size(x,2); [fx{i},s]=marginFilt(x(:,i),s,10); end;
