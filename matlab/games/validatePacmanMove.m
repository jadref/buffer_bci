function [ndxy]=validateMove(map,agents,key,dxy,ndxy)
% get pacman row/col
[pacxy(1),pacxy(2)]=find(agents==key.pacman);
%if ( all(ndxy==0) ) ndxy=dxy; end; % differential encoding of direction
% dest location
dpacxy=pacxy(:)+ndxy;  
% check for tunnel wrap-arround
if (dpacxy(1)<1)            
  dpacxy(1)=size(map,1); 
  ndxy(1)  =dpacxy(1)-pacxy(1);
end
if (dpacxy(1)>size(map,1))  
  dpacxy(1)=1; 
  ndxy(1)  =dpacxy(1)-pacxy(1);
end;
% check for run into wall
if map(dpacxy(1),dpacxy(2))==key.wall
  ndxy(:)=0; % stop if ran into a wall!
end
return;