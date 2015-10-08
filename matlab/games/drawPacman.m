function [map,maph,agents,agentsh,score,pacPtr]=movePacMan(map,maph,agents,agentsh,key,moves,dir,pacPtr)
if ( nargin<8 || isempty(pacPtr) ) 
  pacPtr=find(agents(:)==key.pacman);  
end
% get pacman row/col
[pacrc(1),pacrc(2)]=ind2sub(size(agents),pacPtr);%agents(pacPtr,[2 3]);
% dest location
dpacrc=pacrc(:)+moves.dxy([2 1],dir); % N.B. X=col, Y=row
% make the move
dead=false; score=0;
if map(dpacrc(1),dpacrc(2))==key.wall
  % Do nothing - Ran into a Wall
elseif (agents(dpacrc(1),dpacrc(2))>key.pacman) % ran into ghost
  agents(pacrc(1),pacrc(2))=0; % remove PAC from the board, i.e. he's dead!
else % legal move
  % check for tunnel wrap-arround
  if (dpacrc(2)<=1)            dpacrc(2)=size(map,2)-1; end
  if (dpacrc(2)>=size(map,2))  dpacrc(2)=1; end;
  if ( map(dpacrc(1),dpacrc(2))==key.pellet ) 
    map(dpacrc(1),dpacrc(2)) =key.empty;
    set(maph(dpacrc(1),dpacrc(2)),'visible','off'); % make invisible
    score=score+1; 
  elseif ( map(dpacrc(1),dpacrc(2))==key.powerpellet )
    map(dpacrc(1),dpacrc(2)) =key.empty;
    set(maph(dpacrc(1),dpacrc(2)),'visible','off'); % make invisible
    score=score+10;     
  end;
  pach = agentsh(pacrc(1),pacrc(2));
  xdat=get(pach,'xdata'); ydat=get(pach,'ydata');
  set(pach,'xdata',xdat+moves.dxy(1,dir),'ydata',ydat+moves.dxy(2,dir))
  agents(pacrc(1),pacrc(2))=0; % Clear PAC    
  agentsh(pacrc(1),pacrc(2))=0;
  agents(dpacrc(1),dpacrc(2))=key.pacman; % move pacman
  agentsh(dpacrc(1),dpacrc(2))=pach;
  pacPtr = sub2ind(size(agents),dpacrc(1),dpacrc(2));
end
if ( sum(agents(:)>0)>1 ) 
  keyboard;
end
return;