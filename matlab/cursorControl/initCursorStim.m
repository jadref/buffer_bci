function [ax,h,stimPos,pcoords]=initCursorStim(ax,x,y,scale,nSymbs,arrowcoords,fixcoords)
if ( nargin<1 || isempty(ax) || ~ishandle(ax) ) ax=gca; end;
if ( nargin<2 || isempty(x) ) x=0; end;
if ( nargin<3 || isempty(y) ) y=0; end;
if ( nargin<4 || isempty(scale) ) scale=2; end; % scale of 1=size stim arrows, 2=size arrows ring
if ( nargin<5 || isempty(nSymbs) ) nSymbs=4; end;
if ( nargin<6 || isempty(arrowcoords) ) arrowcoords=[1 -1 -1 1 1;1 1 -1 -1 1]; end; % def to box
if ( nargin<7 || isempty(fixcoords) ) fixcoords=[0 1 0 -1 0;1 0 -1 0 1]; end; % def to diamond
axes(ax);
arrowcoords=arrowcoords*.5*scale(1);
theta=linspace(0,2*pi*(nSymbs-1)/nSymbs,nSymbs); 
stimPos=[x+cos(theta)*scale(min(end,2)); y+sin(theta)*scale(min(end,2))];
for hi=1:nSymbs; 
  pcoords(:,:,hi) = [cos(theta(hi)) -sin(theta(hi));sin(theta(hi)) cos(theta(hi))]*arrowcoords;
  h(hi)=patch(stimPos(1,hi)+pcoords(1,:,hi),stimPos(2,hi)+pcoords(2,:,hi),[0 0 0],'edgecolor',[1 1 1],...
              'CDataMapping','direct');%,'EraseMode','background');
%  h(hi)=rectangle('curvature',[1 1],'position',[stimPos(:,hi)-stimRadius/2;stimRadius*[1;1]],...
%                  'facecolor',[0 0 0],'edgecolor',[1 1 1],'linewidth',2); 
end;
% add a fixitation point in the center
stimPos(:,nSymbs+1)=[x;y];
h(nSymbs+1) = patch(x+fixcoords(1,:)*.3.*scale(1),y+fixcoords(2,:)*.3.*scale(1),[1 1 1],'edgeColor',[1 1 1],'CDataMapping','direct');