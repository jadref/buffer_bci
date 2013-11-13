function [ndxy]=validateSokobanMove(map,agents,key,dxy,ndxy)
%get location of player
[manxy(1),manxy(2)]=find(agents==key.man);
% dest location
dmanxy=manxy(:)+ndxy;  % N.B. row=y, col=x
% if space to move then is OK
if (agents(dmanxy(1),dmanxy(2))==key.block) % is block
  if ( ~agents(dmanxy(1)+ndxy(1),dmanxy(2)+ndxy(2)) && ... % no agent after
       ( map(dmanxy(1)+ndxy(1),dmanxy(2)+ndxy(2))==key.empty || ... % is open after
         map(dmanxy(1)+ndxy(1),dmanxy(2)+ndxy(2))==key.goal)  ) % is goal after
    return; % move is OK
  else
    ndxy(:)=0;
  end
elseif (map(dmanxy(1),dmanxy(2))==key.empty || map(dmanxy(1),dmanxy(2))==key.goal) 
  return;
else
  ndxy(:)=0;
end
