function s=getsampTime(t,mb)
% convert from wall time to sample time
if ( nargin<2 || isempty(mb) ) global rtclockmb; mb=rtclockmb; end;
if ( isempty(mb) ) % return a I don't know sample number
  s=-1; 
else
  if ( nargin<1 || isempty(t) ) t=getwTime(); end;
  s=t*mb(1)+mb(2);
end
return;