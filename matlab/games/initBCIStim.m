function [ax,h,stimPos,pcoords]=initBCIStim(ax,x,y,scale,nSymbs,arrowcoords)
if ( nargin<1 || isempty(ax) || ~ishandle(ax) ) ax=gca; end;
if ( nargin<2 || isempty(x) ) x=0; end;
if ( nargin<3 || isempty(y) ) y=0; end;
if ( nargin<4 || isempty(scale) ) scale=2; end;
if ( nargin<5 || isempty(nSymbs) ) nSymbs=4; end;
if ( nargin<6 || isempty(arrowcoords) ) arrowcoords=[1 -1 -1 1 1;1 1 -1 -1 1]; end; % def to box
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
