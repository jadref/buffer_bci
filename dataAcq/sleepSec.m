function []=sleepSec(t);
% sleep for the given number of seconds, use the accurate java.Thread.sleep call
%
% []=sleepSec(t);
%
% N.B. use initsleepSec to initialize!
% N.B. this function is only a placeholder the actual function is in the global variable: sleepSec
%
% See also: initsleepSec
global sleepSec;
feval(sleepSec,t);