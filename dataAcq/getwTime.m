function [t]=getwTime();
% get the current wall-time using the accurate java.millisecs call
%
% []=sleepSec(t);
%
% N.B. use initgetwTime to initialize!
%
% See also: initgetwTime
global getwTime;
t=feval(getwTime); 