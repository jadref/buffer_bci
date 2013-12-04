function []=sleepSec(t);
% sleep for the given number of seconds, use the accurate java.Thread.sleep call
%
% []=sleepSec(t);
%
% N.B. use initsleepSec to initialize!
%
% See also: initsleepSec
global sleepSec;
feval(sleepSec,t);