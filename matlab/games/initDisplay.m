function [arenaax,maph,agentsh,titleax,scoreh,moveh]=initDisplay(fig,map,agents,key,score,pacmancoords)
if ( isempty(fig) ) fig=gcf(); end;
figure(fig);
set(fig,'Name','Pacman','units','normalized','position',[0 0 1 1],...
    'color',[0 0 0],'menubar','none','toolbar','none',...
    'backingstore','on','renderer','painters','doublebuffer','on','Interruptible','off');
clf;
arenaax=axes('position',[0.025 0.05 .825 .85],'units','normalized','visible','off','box','off',...
             'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
             'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
             'xlim',[.5 size(map,2)+.5],'ylim',[.5 size(map,1)+.5],'Ydir','reverse');%,'DataAspectRatio',[1 1 1]);
%arenarect=[1 1 size(map,2) size(map,1)]; % box in which the arena lives
%set(arenaax,);
% build a specific color map.
cmap=zeros(max(max([map(:);agents(:)]),10),3);
cmap(key.empty,:)       =[0 0 0];
cmap(key.wall,:)        =[.5 .5 .5];
cmap(key.pellet,:)      =[.8 .8 .8];
cmap(key.powerpellet,:) =[.8 .8 .8];
cmap(key.ghostbox,:)    =[.25 .25 1];
cmap(key.ghostdoor,:)   =[.5 .5 1];
cmap(key.ghost,:)       =[1 0 0];
cmap(key.pacman,:)      =[1 1 0];
colormap(cmap);
%alphamap([0 0 0;1 1 1]);

% draw the map as a bitmap
%maph=image(map,'CDataMapping','direct');%,'Clim',[0 10]);

% draw the static parts of the map as a bitmap
bg=zeros(size(map),'int8'); bg(:)=map; 
bg(map==key.pellet | map==key.powerpellet | map==key.pacman | map==key.ghost)=key.empty;
bgh=image(bg,'CDataMapping','direct');
% argh image resets lots of axes properties... set them back
set(arenaax,'visible','off','box','off',...
            'xtick',[],'xticklabelmode','manual','xticklabel',[],...
            'ytick',[],'yticklabelmode','manual','yticklabel',[],...
            'color',[0 0 0],'drawmode','fast',...
            'xlim',[.5 size(map,2)+.5],'ylim',[.5 size(map,1)+.5],'Ydir','reverse');%,'DataAspectRatio',[1 1 1]);
% mini-map
miniax=axes('position',[.875 .775 .125 .125],'color',[0 0 0]);
minih =image(bg,'CDataMapping','direct');
set(miniax,'visible','off','box','off','xtick',[],'xticklabel',[],'ytick',[],'yticklabel',[],'color',[0 0 0]);

axes(arenaax);

% draw the map as a set of patches
thetas=linspace(0,2*pi,13); for i=1:numel(thetas); xc(i)=cos(thetas(i)); yc(i)=sin(thetas(i)); end;
maph=zeros(size(map));
for r=1:size(map,1);
  for c=1:size(map,2);
    % convert row/col to axes co-ords
    x = c; 
    y = r;
    switch (map(r,c));
     case key.empty;        %maph(r,c)=patch(c+[-1 -1 +1 +1]/2,y+[-1 +1 +1 -1]/2,cmap(key.empty,:),'Linestyle','none');
     case key.wall;         %maph(r,c)=patch(x+[-1 +1 +1 -1]/2,y+[-1 -1 +1 +1]/2,cmap(key.wall,:),'Linestyle','none','CDataMapping','direct','EraseMode','background');
     case key.pellet;       
      rad=.1; 
      %maph(r,c) =rectangle('position',[x-rad/2 y-rad/2 rad rad],'curvature',[1 1],'EraseMode','background','facecolor',cmap(key.pellet,:),'edgecolor',cmap(key.pellet,:)); 
      %maph(r,c)=plot(x,y,'.','markerSize',10,'color',cmap(key.pellet,:));
      %maph(r,c)=patch(x+xc*rad,y+yc*rad,cmap(key.pellet,:),'Linestyle','none','CDataMapping','direct');
     case key.powerpellet;  
      rad=.2; 
      %maph(r,c) =rectangle('position',[x-rad/2 y-rad/2 rad rad],'curvature',[1 1],'EraseMode','background','facecolor',cmap(key.pellet,:),'edgecolor',cmap(key.pellet,:)); 
      %maph(r,c)=plot(x,y,'.','markerSize',20,'color',cmap(key.powerpellet,:));
      %maph(r,c)=patch(x+xc*rad,y+yc*rad,cmap(key.powerpellet,:),'Linestyle','none','CDataMapping','direct');
     case key.ghostbox;     %maph(r,c)=patch(x+[-1 +1 +1 -1]/2,y+[-1 -1 +1 +1]/2,cmap(key.ghostbox,:),'Linestyle','none','CDataMapping','direct','EraseMode','background');
     case key.ghostdoor;    %maph(r,c)=patch(x+[-1 +1 +1 -1]/2,y+[-1 -1 +1 +1]/2,cmap(key.ghostdoor,:),'Linestyle','none','CDataMapping','direct','EraseMode','background');
     otherwise;
    end
    hold on;
  end
end

hold on;
% draw the agents as patches
ags=find(agents(:)>0);
agentsh=zeros(size(agents));
ghosti=0;
for i=1:numel(ags);
  [r,c]=ind2sub(size(agents),ags(i));
  % convert row/col to axes co-ords
  x = c; 
  y = r;
  switch agents(r,c);
   case key.pacman;  agentsh(r,c) = patch(x+pacmancoords(1,:)/2*.7,y+pacmancoords(2,:)/2*.7,cmap(key.pacman,:),...
                                          'Linestyle','none','CDataMapping','direct');%,'EraseMode','background');
   case key.ghost;   agentsh(r,c) = patch(x+[-1 +1 +1 -1]/2*.7,y+[-1 -1 +1 +1]/2*.7,...
                                          cmap(key.ghost+ghosti,:),...
                                          'Linestyle','none','CDataMapping','direct');%,'EraseMode','background');
    ghosti=ghosti+1;
  end
end
%agentsh=0;
%agentsh=image(agents,'CDataMapping','direct','alphaDataMapping','none','alphaData',agents>0);
% draw the score at the top
titleax=axes('position',[0.025 0.9 .95 .1],'units','normalized','visible','off','box','off','color',[0 0 0],'drawmode','fast','xlim',[0 1],'ylim',[0 1]);
moveh =text(0,.5,'Moves : 0','HorizontalAlignment','left','color',[1 1 1]);
scoreh=text(1,.5,'Score : 0','HorizontalAlignment','right','color',[1 1 1]);
