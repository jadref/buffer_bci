function [ndxy]=validateMove(map,agents,key,dxy,ndxy)
if ( isstruct(agents) ) agents=agents.map; end;
% get pacman row/col
[pacrc(1),pacrc(2)]=find(agents==key.snakehead);
%if ( all(ndxy==0) ) ndxy=dxy; end; % differential encoding of direction
% dest location
dpacrc=pacrc(:)+ndxy([2 1]);  % N.B. row=y, col=x
% check for run into wall
if( all(ndxy==-dxy) ) % trying to move backwards
  ndxy=dxy;
elseif ( all(ndxy(:)==0) ) % trying NOT to move
  % move away from tail
  dxy = -(agents.snake(:,1)-agents.snake(:,2));
end
return;