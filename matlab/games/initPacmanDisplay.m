function [arenaax,maph,agentsh,titleax,scoreh,moveh,cmap]=initPacmanDisplay(fig,map,agents,key,score,pacmancoords)
if ( isempty(fig) ) fig=figure(2); end;
figure(fig);
set(fig,'Name','Pacman','units','normalized',...%'position',[0 0 1 1],...
    'color',[0 0 0],'menubar','none','toolbar','none',...
    'renderer','painters','doublebuffer','on','Interruptible','off');%'backingstore','on',
if ( ~exist('OCTAVE_VERSION') ) set(fig,'backingstore','on'); end;
clf;
arenaax=axes('position',[0.025 0.05 .825 .85],'units','normalized','visible','off','box','off',...
             'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
             'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
             'xlim',[.5 size(map,2)+.5],'ylim',[.5 size(map,1)+.5],'Ydir','normal');%,'DataAspectRatio',[1 1 1]);
%arenarect=[1 1 size(map,2) size(map,1)]; % box in which the arena lives
%set(arenaax,);
% build a specific color map.
cmap=zeros(max(max([map(:);agents(:)]),10),3);
cmap(key.empty+1,:)       =[0 0 0];
cmap(key.wall+1,:)        =[.5 .5 .5];
cmap(key.pellet+1,:)      =[.8 .8 .8];
cmap(key.powerpellet+1,:) =[.8 .8 .8];
cmap(key.ghostbox+1,:)    =[.25 .25 1];
cmap(key.ghostdoor+1,:)   =[.5 .5 1];
cmap(key.ghost+1,:)       =[1 0 0];
cmap(key.pacman+1,:)      =[1 1 0];
colormap(cmap);
%alphamap([0 0 0;1 1 1]);

% draw the static parts of the map as a bitmap
bg=zeros(size(map),'int8'); bg(:)=map; 
bg(map==key.pellet | map==key.powerpellet | map==key.pacman | map==key.ghost)=key.empty;
if ( ~exist('OCTAVE_VERSION') )
  bgh=image(bg'+1,'CDataMapping','direct');
else
  bgh=image(single(bg'+1),'CDataMapping','direct');
end
% argh image resets lots of axes properties... set them back
set(arenaax,'visible','off','box','off',...
            'xtick',[],'xticklabelmode','manual','xticklabel',[],...
            'ytick',[],'yticklabelmode','manual','yticklabel',[],...
            'color',[0 0 0],'drawmode','fast',...
            'xlim',[.5 size(map,1)+.5],'ylim',[.5 size(map,2)+.5],'Ydir','normal');%,'DataAspectRatio',[1 1 1]);
% mini-map
miniax=axes('position',[.875 .775 .125 .125],'color',[0 0 0]);
if ( ~exist('OCTAVE_VERSION') )
  minih=image(bg'+1,'CDataMapping','direct');
else
  minih=image(single(bg'+1),'CDataMapping','direct');
end
set(miniax,'visible','off','box','off','xtick',[],'xticklabel',[],'ytick',[],'yticklabel',[],'color',[0 0 0],...
           'Ydir','normal');

axes(arenaax);

% draw the map as a set of patches
thetas=linspace(0,2*pi,13); for i=1:numel(thetas); xc(i)=cos(thetas(i)); yc(i)=sin(thetas(i)); end;
maph=zeros(size(map));
for x=1:size(map,1);
  for y=1:size(map,2);
    switch (map(x,y));
     case key.empty;        %maph(x,y)=patch(c+[-1 -1 +1 +1]/2,y+[-1 +1 +1 -1]/2,cmap(key.empty+1,:),'Linestyle','none');
     case key.wall;         %maph(x,y)=patch(x+[-1 +1 +1 -1]/2,y+[-1 -1 +1 +1]/2,cmap(key.wall+1,:),'Linestyle','none','CDataMapping','direct','EraseMode','background');
     case key.pellet;       
      rad=.1; 
      %maph(x,y) =rectangle('position',[x-rad/2 y-rad/2 rad rad],'curvature',[1 1],'EraseMode','background','facecolor',cmap(key.pellet+1,:),'edgecolor',cmap(key.pellet+1,:)); 
      %maph(x,y)=plot(x,y,'.','markerSize',10,'color',cmap(key.pellet+1,:));
		col=cmap(key.pellet+1,:);
      maph(x,y)=patch(x+xc*rad,y+yc*rad,col,'edgecolor',col,'facecolor',col,'Linewidth',2,'CDataMapping','direct');
     case key.powerpellet;  
      rad=.2; 
      %maph(x,y) =rectangle('position',[x-rad/2 y-rad/2 rad rad],'curvature',[1 1],'EraseMode','background','facecolor',cmap(key.pellet+1,:),'edgecolor',cmap(key.pellet+1,:)); 
 %maph(x,y)=plot(x,y,'.','markerSize',20,'color',cmap(key.powerpellet+1,:));
		col=cmap(key.powerpellet+1,:);
      maph(x,y)=patch(x+xc*rad,y+yc*rad,col,'edgecolor',col,'facecolor',col,'Linewidth',2,'CDataMapping','direct');
     case key.ghostbox;     %maph(x,y)=patch(x+[-1 +1 +1 -1]/2,y+[-1 -1 +1 +1]/2,cmap(key.ghostbox+1,:),'Linestyle','none','CDataMapping','direct','EraseMode','background');
     case key.ghostdoor;    %maph(x,y)=patch(x+[-1 +1 +1 -1]/2,y+[-1 -1 +1 +1]/2,cmap(key.ghostdoor+1,:),'Linestyle','none','CDataMapping','direct','EraseMode','background');
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
  [x,y]=ind2sub(size(agents),ags(i));
  switch agents(x,y);
    case key.pacman;
		col=cmap(key.pacman+1,:);
		agentsh(x,y) = patch(x+pacmancoords(1,:)/2*.7,y+pacmancoords(2,:)/2*.7,col,...
                           'Linewidth',2,'edgecolor',col,'facecolor',col,'CDataMapping','direct');%,'EraseMode','background');
    case key.ghost;
		col=cmap(key.ghost+1+ghosti,:);
		agentsh(x,y) = patch(x+[-1 +1 +1 -1]/2*.7,y+[-1 -1 +1 +1]/2*.7,col,...
									'edgecolor',col,'facecolor',col,...
                           'CDataMapping','direct');%,'EraseMode','background');
    ghosti=ghosti+1;
  end
end
%agentsh=0;
%agentsh=image(agents,'CDataMapping','direct','alphaDataMapping','none','alphaData',agents>0);
% draw the score at the top
titleax=axes('position',[0.025 0.9 .95 .1],'units','normalized','visible','off','box','off','color',[0 0 0],'drawmode','fast','xlim',[0 1],'ylim',[0 1]);
moveh =text(0,.5,'Moves : 0','HorizontalAlignment','left','color',[1 1 1]);
scoreh=text(1,.5,'Score : 0','HorizontalAlignment','right','color',[1 1 1]);
