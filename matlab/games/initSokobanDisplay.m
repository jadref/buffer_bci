function [arenaax,maph,agentsh,titleax,scoreh,moveh]=initSokobanDisplay(fig,map,agents,key,score,mancoords,blockcoords)
if ( nargin<6 || isempty(mancoords) )   mancoords=loadPatchCoords('man.coords'); end;
if ( nargin<7 || isempty(blockcoords) ) blockcoords=loadPatchCoords('block.coords'); end;
if ( isempty(fig) ) fig=get(0,'currentfigure'); if(isempty(fig))fig=figure();end; end;
set(fig,'Name','Sokoban','units','normalized',...%,'position',[0 0 1 1],...
        'color',[0 0 0],'backingstore','on','menubar','none','toolbar','none');

% manually clear all objects in this figure
hs=findobj(fig); delete(hs(2:end));

arenaax=axes('position',[0.025 0.05 .825 .85],'units','normalized','visible','off','box','off',...
             'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
             'color',[0 0 0],'drawmode','fast',...
             'xlim',[.5 size(map,2)+.5],'ylim',[.5 size(map,1)+.5],'Ydir','normal');%,'DataAspectRatio',[1 1 1]);

% build a specific color map.
cmap=zeros(max(max([map(:);agents(:)]),10),3);
cmap(key.empty+1,:) =[0 0 0];
cmap(key.wall+1,:)  =[.5 .5 .5];
cmap(key.block+1,:) =[0 0 1];
cmap(key.goal+1,:)  =[0 1 0];
cmap(key.man+1,:)   =[1 1 0];
colormap(cmap);

% draw the static parts of the map as a bitmap
bg=zeros(size(map),'int8'); 
bg(:)=map; 
bg(map==key.man | map==key.block)=key.empty;
bgh=image(bg'+1,'CDataMapping','direct');
% argh image resets lots of axes properties... set them back
set(arenaax,'visible','off','box','off',...
            'xtick',[],'xticklabelmode','manual','xticklabel',[],...
            'ytick',[],'yticklabelmode','manual','yticklabel',[],...
            'color',[0 0 0],'drawmode','fast',...
            'xlim',[.5 size(map,1)+.5],'ylim',[.5 size(map,2)+.5],'Ydir','normal');%,'DataAspectRatio',[1 1 1]);
% mini-map
miniax=axes('position',[.875 .775 .125 .125],'color',[0 0 0]);
minih =image(bg'+1,'CDataMapping','direct');
set(miniax,'visible','off','box','off','xtick',[],'xticklabel',[],...
           'ytick',[],'yticklabel',[],'color',[0 0 0],...
           'Ydir','normal');

axes(arenaax);

% draw the movable/changable parts of the map
maph=[];
%blockcoords=[-1 +1 +1 -1;-1 -1 +1 +1];
agentsh=zeros(size(map));
for x=1:size(map,1);
  for y=1:size(map,2);
    switch (agents(x,y));
     case key.empty;
     case key.wall; 
     case key.goal;
     case key.block;       
      agentsh(x,y)=patch(x+blockcoords(1,:)/2,y+blockcoords(2,:)/2,cmap(key.block+1,:),...
                         'Linestyle','none','CDataMapping','direct');%,'EraseMode','background');
     case key.man;
      agentsh(x,y)=patch(x+mancoords(1,:)/2*.7,y+mancoords(2,:)/2*.7,cmap(key.man+1,:),...
                         'Linestyle','none','CDataMapping','direct');%,'EraseMode','background');
     otherwise;
    end
    hold on;
  end
end

% draw the score at the top
titleax=axes('position',[0.025 0.9 .95 .1],'units','normalized','visible','off','box','off','color',[0 0 0],'drawmode','fast','xlim',[0 1],'ylim',[0 1]);
moveh =text(0,.5,'Moves : 0','HorizontalAlignment','left','color',[1 1 1]);
scoreh=text(1,.5,'Score : 0','HorizontalAlignment','right','color',[1 1 1]);
