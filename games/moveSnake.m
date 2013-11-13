function [map,maph,agents,agentsh,dxy,gameState]=moveSnake(ax,map,maph,agents,agentsh,key,dxy,gameState,track)
if ( nargin<8 || isempty(gameState) ) 
  gameState=struct('dead',false,'score',0,'grow',0);
end
if ( nargin<9 || isempty(track) ) track=false; end;
dead=gameState.dead; score=gameState.score; grow=gameState.grow;
if( all(dxy==0) ) return; end; % nothing to do!
% get snake row/col
[pacxy(1,1),pacxy(2,1)]=find(agents.map==key.snakehead);
% dest location
dpacxy=pacxy+dxy; % N.B. X=col, Y=row
% make the move
if( map(dpacxy(1),dpacxy(2))~=key.empty ) % if not empty ran into something, i.e. wall
  dxy(:)=0;
  dead=true;  
elseif (agents.map(dpacxy(1),dpacxy(2))==key.snakebody ) % ran into myself
  dxy(:)=0;
  dead=true;
end;
if ( dead ) % he's dead!
  map(pacxy(1),pacxy(2))=key.empty;
  gameState.dead=true;
  return;
else
  %score=score+1; % 1 point for surviving
end
% legal move
if ( agents.map(dpacxy(1),dpacxy(2))==key.pellet ) 
  agents.map(dpacxy(1),dpacxy(2)) =key.empty;
  set(agentsh(dpacxy(1),dpacxy(2)),'visible','off'); % make invisible
  score=score+1; 
  grow =grow+1; % 1 new segement
elseif ( agents.map(dpacxy(1),dpacxy(2))==key.powerpellet )
  agents.map(dpacxy(1),dpacxy(2)) =key.empty;
  set(agentsh(dpacxy(1),dpacxy(2)),'visible','off'); % make invisible
  score=score+3;     
  grow =grow+3; % 3 new segements
end;
if ( track )
  % now move the axes also
  set(ax,'xlim',get(ax,'xlim')+dxy(1),'ylim',get(ax,'ylim')+dxy(2));
end
% now move the snake
pach = agentsh(pacxy(1),pacxy(2));
% move the head
xdat=get(pach,'xdata'); ydat=get(pach,'ydata');
set(pach,'xdata',xdat+dxy(1),'ydata',ydat+dxy(2))
agents.map(pacxy(1),pacxy(2))=0; % Clear PAC    
agentsh(pacxy(1),pacxy(2))=0;
agents.map(dpacxy(1),dpacxy(2))=key.snakehead; % move snake
agentsh(dpacxy(1),dpacxy(2))=pach;

% get the tail info so we can move it (or copy it)
tailxy = agents.snake(:,end);
tailh  = agentsh(tailxy(1),tailxy(2));
xdat=get(tailh,'xdata')-tailxy(1); ydat=get(tailh,'ydata')-tailxy(2);  
if ( grow>0 ) % add new patch in the old head location
  agents.map(pacxy(1),pacxy(2)) =key.snakebody;
  agentsh(pacxy(1),pacxy(2))=mkSnakeSprite(ax,pacxy(1),pacxy(2),agents.map(pacxy(1),pacxy(2)),key);
  grow=max(0,grow-1);
  agents.snake = [dpacxy agents.snake]; % add the head to the snake list
else % move the tail patch into the old head place  
  agents.map(tailxy(1),tailxy(2))=0; % clear tail
  agentsh(tailxy(1),tailxy(2))=0;
  set(tailh,'xdata',pacxy(1)+xdat,'ydata',pacxy(2)+ydat); % move the tail to old head
  agents.map(pacxy(1),pacxy(2))=key.snakebody; % move snake
  agentsh(pacxy(1),pacxy(2))   =tailh;
  agents.snake = [dpacxy agents.snake(:,1:end-1)]; % add head, remove tail
  grow=min(0,grow+1);
end
gameState.grow=grow;
gameState.score=score;
gameState.dead=dead;
return;