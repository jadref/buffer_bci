function [map,maph,agents,agentsh,score]=movePacMan(ax,map,maph,agents,agentsh,key,dxy,track)
if ( nargin<8 || isempty(track) ) track=false; end;
dead=false; score=0;
% get pacman row/col
[pacxy(1,1),pacxy(2,1)]=find(agents==key.pacman);
% dest location
dpacxy=pacxy+dxy; % N.B. X=col, Y=row
if( all(dxy==0) ) return; end; % nothing to do!
% check for tunnel wrap-arround
%if (dpacxy(2)<1)            dpacxy(2)=size(map,2); end
%if (dpacxy(2)>size(map,2))  dpacxy(2)=1; end;
% make the move
if map(dpacxy(1),dpacxy(2))==key.wall
  % Do nothing - Ran into a Wall
elseif (agents(dpacxy(1),dpacxy(2))>key.pacman) % ran into ghost
  agents(pacxy(1),pacxy(2))=0; % remove PAC from the board, i.e. he's dead!
else % legal move
  if ( map(dpacxy(1),dpacxy(2))==key.pellet ) 
    map(dpacxy(1),dpacxy(2)) =key.empty;
    set(maph(dpacxy(1),dpacxy(2)),'visible','off'); % make invisible
    score=score+1; 
  elseif ( map(dpacxy(1),dpacxy(2))==key.powerpellet )
    map(dpacxy(1),dpacxy(2)) =key.empty;
    set(maph(dpacxy(1),dpacxy(2)),'visible','off'); % make invisible
    score=score+10;     
  end;
  if ( track ) 
    % now move the axes also
    set(ax,'xlim',get(ax,'xlim')+dxy(1),'ylim',get(ax,'ylim')+dxy(2));
  end
  % now move the pacman
  pach = agentsh(pacxy(1),pacxy(2));
  xdat=get(pach,'xdata'); ydat=get(pach,'ydata');
  set(pach,'xdata',xdat+dxy(1),'ydata',ydat+dxy(2))
  agents(pacxy(1),pacxy(2))=0; % Clear PAC    
  agentsh(pacxy(1),pacxy(2))=0;
  agents(dpacxy(1),dpacxy(2))=key.pacman; % move pacman
  agentsh(dpacxy(1),dpacxy(2))=pach;
end
return;