function [rect]=rel2pixel(wPtr,rect)
% simple utility function to convert from relative coordinates to pixel coordinates
%  
%  [rect]=rel2pixel(wPtr,rect)
%
% Inputs:
%   wPtr - handle to the PTB window to convert for
%   rect - rectangle in relative coords to convert, [x y w h] or [ L T R B ] format
% Outputs:
%   rect - rectangel in pixel co-ordinates in input format
if ( numel(wPtr)==1 ) [width,height]=Screen('WindowSize',wPtr); 
else                  width=wPtr(1);height=wPtr(2);
end
if ( all(rect<=1) && all(rect>=0) ) % convert from rel to abs coords
   rect([1 3])=rect([1 3])*width; rect([2 4])=rect([2 4])*height;
end
idx=[2 4];idx=idx(rect(idx)<0);rect(idx)=rect(idx)+height+1;
idx=[1 3];idx=idx(rect(idx)<0);rect(idx)=rect(idx)+width+1;
rect=rect(:);
return;