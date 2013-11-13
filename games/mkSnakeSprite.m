function [h]=mkSnakeSprite(ax,x,y,type,key,segcoords,cmap)
if ( nargin<6 || isempty(segcoords)) segcoords='seg.coords'; end;
if ( ischar(segcoords) ) segcoords=loadPatchCoords(segcoords); end;
if ( nargin<7 || isempty(cmap) )
  cmap(key.empty+1,:)       =[0 0 0];
  cmap(key.wall+1,:)        =[.5 .5 .5];
  cmap(key.pellet+1,:)      =[.8 .1 .1];
  cmap(key.powerpellet+1,:) =[.8 .1 .1]; 
  cmap(key.snakehead+1,:)   =[0  1   0];
  cmap(key.snakebody+1,:)   =[.1 .6 .1];
end

axes(ax); % make arena axes current
thetas=linspace(0,2*pi,13); for i=1:numel(thetas); xc(i)=cos(thetas(i)); yc(i)=sin(thetas(i)); end;
switch (type);
 case key.pellet;       
  rad=.1; 
  h=patch(x+xc*rad,y+yc*rad,cmap(key.pellet+1,:),'Linestyle','none','CDataMapping','direct');
 case key.powerpellet;  
  rad=.2; 
  h=patch(x+xc*rad,y+yc*rad,cmap(key.powerpellet+1,:),'Linestyle','none','CDataMapping','direct');
 case key.snakehead;       
  h=patch(x+segcoords(1,:),y+segcoords(2,:),cmap(key.snakehead+1,:),...
          'Linestyle','none','CDataMapping','direct','EraseMode','background');
 case key.snakebody;
  rad=1.0;
  h=patch(x+segcoords(1,:)*rad,y+segcoords(2,:)*rad,cmap(key.snakebody+1,:),...
          'Linestyle','none','CDataMapping','direct');%,'EraseMode','background');
 otherwise;
  h=0;
end
