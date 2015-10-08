function [map,maph,agents,agentsh]=moveSokoban(ax,map,maph,agents,agentsh,key,dxy,track)
if ( nargin<8 || isempty(track) ) track=false; end;
% get man row/col
[manxy(1),manxy(2)]=find(agents==key.man);
% dest location
dmanxy=manxy(:)+dxy; % N.B. X=col, Y=row
if( all(dxy==0) ) return; end; % nothing to do!
% make the move
if ( agents(dmanxy(1),dmanxy(2))==key.block ) % move block first
  dblkxy=dmanxy+dxy;
  blkh=agentsh(dmanxy(1),dmanxy(2));
  xdat=get(blkh,'xdata'); ydat=get(blkh,'ydata');
  set(blkh,'xdata',xdat+dxy(1),'ydata',ydat+dxy(2))
  agents(dblkxy(1),dblkxy(2))=key.block; % move block
  agentsh(dblkxy(1),dblkxy(2))=blkh;  
  agents(dmanxy(1),dmanxy(2))=0;  % Clear orgin
  agentsh(dmanxy(1),dmanxy(2))=0;
end
if (track)
% now move the axes also
set(ax,'xlim',get(ax,'xlim')+dxy(1),'ylim',get(ax,'ylim')+dxy(2));
end
% move the man
manh = agentsh(manxy(1),manxy(2));
xdat=get(manh,'xdata'); ydat=get(manh,'ydata');
set(manh,'xdata',xdat+dxy(1),'ydata',ydat+dxy(2))
agents(dmanxy(1),dmanxy(2))=key.man; % move man
agentsh(dmanxy(1),dmanxy(2))=manh;
agents(manxy(1),manxy(2))=0; % Clear MAN    
agentsh(manxy(1),manxy(2))=0;
return;