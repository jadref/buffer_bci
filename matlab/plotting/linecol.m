function [s]=linecol(c)
% [s]=linecol(c)
mlock;  % lock this function in memory so clears don't affect it.
cols='bgrcmyk';
persistent curcol; 
if ( isempty(curcol) ) curcol=0; else curcol=curcol+1; end; % init static
if ( nargin > 0 && ~isempty(c) )  curcol=c; end; % arg over-rides
s=[cols(mod(curcol-1,length(cols))+1)];          % set color
