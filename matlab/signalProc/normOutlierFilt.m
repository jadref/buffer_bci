function [x,s]=normOutlierFilt(x,s,margin)
% send event when accumulated margin between best and 2nd best prediction is greater than margin
%
%   [x,s]=normOutlierFilt(x,s,margin)
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
sx=sort(s.x);
if( sx(1)>=sx(2)+margin )
  x=s.x;
  % clear internal state
  s.x(:)=0;
else
  x = []; % don't send
end
return;
