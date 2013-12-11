function [t]=getwTime();
% get the current wall-time using the accurate java.millisecs call
%
% []=sleepSec(t);
%
% N.B. use initgetwTime to initialize!
% N.B. this function is only a placeholder the actual function is in the global variable: getwTime
%
% See also: initgetwTime
global getwTime;
t=feval(getwTime); 