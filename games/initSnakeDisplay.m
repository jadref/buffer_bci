function [arenaax,maph,agentsh,titleax,scoreh,moveh]=initSnakeDisplay(fig,map,agents,key,score,segcoords)
if ( nargin<6 || isempty(segcoords) ) segcoords='seg.coords'; end;
if ( isempty(fig) ) fig=gcf(); end;
figure(fig);
set(fig,'Name','Snake','units','normalized',...%,'position',[0 0 1 1],...
    'color',[0 0 0],'menubar','none','toolbar','none');
if ( ispc() )
  set(fig,'backingstore','on','renderer','painters','doublebuffer','on','Interruptible','off');
else
  %opengl software; % hardware seems to fail!
  set(fig,'backingstore','on','renderer','painters','doublebuffer','on','Interruptible','off');
end
clf;
arenaax=axes('position',[0.025 0.05 .825 .85],'units','normalized','visible','off','box','off',...
             'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
             'color',[0 0 0],'drawmode','fast',...
             'xlim',[.5 size(map,2)+.5],'ylim',[.5 size(map,1)+.5],'Ydir','normal');%,'DataAspectRatio',[1 1 1]);

% build a specific color map.
cmap=zeros(max(max([map(:);agents(:)]),10),3);
cmap(key.empty+1,:)       =[0 0 0];
cmap(key.wall+1,:)        =[.5 .5 .5];
cmap(key.pellet+1,:)      =[.8 .1 .1];
cmap(key.powerpellet+1,:) =[.8 .1 .1]; 
cmap(key.snakehead+1,:)   =[0  1   0];
cmap(key.snakebody+1,:)   =[.1 .6 .1];
colormap(cmap);

% load the snake info
if ( ischar(segcoords) ) segcoords = loadPatchCoords(segcoords); end;

% draw the static parts of the map as a bitmap
bg=zeros(size(map),'int8'); 
bg(:)=map; 
bg(map==key.snakehead | map==key.snakebody | map==key.pellet | map==key.powerpellet)=key.empty;
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
set(miniax,'visible','off','box','off','xtick',[],'xticklabel',[],'ytick',[],'yticklabel',[],'color',[0 0 0],...
           'Ydir','normal');

axes(arenaax);

% draw the movable/changable parts of the map
thetas=linspace(0,2*pi,13); for i=1:numel(thetas); xc(i)=cos(thetas(i)); yc(i)=sin(thetas(i)); end;
maph=[];
agentsh=zeros(size(map));
for x=1:size(map,1);
  for y=1:size(map,2);
    agentsh(x,y) = mkSnakeSprite(arenaax,x,y,agents(x,y),key,segcoords,cmap);
    hold on;
  end
end

% draw the score at the top
titleax=axes('position',[0.025 0.9 .95 .1],'units','normalized','visible','off','box','off','color',[0 0 0],'drawmode','fast','xlim',[0 1],'ylim',[0 1]);
moveh =text(0,.5,'Moves : 0','HorizontalAlignment','left','color',[1 1 1]);
scoreh=text(1,.5,'Score : 0','HorizontalAlignment','right','color',[1 1 1]);
