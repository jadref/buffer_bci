function [k]=waitkey(h)
% [k]=waitkey(h) -- wait for and return key press in window h
if ( nargin < 1 ) h=gcf;end
set(h,'keypressfcn','uiresume'); uiwait; k=get(h,'Currentkey');
set(h,'keypressfcn',[]);