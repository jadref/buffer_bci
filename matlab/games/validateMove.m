function [ndxy]=validateMove(map,agents,key,dxy,ndxy,pacPtr)
if ( nargin<8 || isempty(pacPtr) ) 
  pacPtr=find(agents(:)==key.pacman);  
end
% get pacman row/col
[pacrc(1),pacrc(2)]=ind2sub(size(agents),pacPtr);%agents(pacPtr,[2 3]);
%if ( all(ndxy==0) ) ndxy=dxy; end; % differential encoding of direction
% dest location
dpacrc=pacrc(:)+ndxy([2 1]);  % N.B. row=y, col=x
% check for tunnel wrap-arround
if (dpacrc(2)<1)            
  dpacrc(2)=size(map,2); 
  ndxy(1)  =dpacrc(2)-pacrc(2);
end
if (dpacrc(2)>size(map,2))  
  dpacrc(2)=1; 
  ndxy(1)  =dpacrc(2)-pacrc(2);
end;
% check for run into wall
if map(dpacrc(1),dpacrc(2))==key.wall
  ndxy(:)=0; % stop if ran into a wall!
end
return;