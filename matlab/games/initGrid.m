function [hdls,symbols,opts]=initGrid(symbols,varargin)
% layout a set of symbols in a figure axes in the shape the input symbols
%
% [hdls]=initGrid(symbols,varargin)
%
% Inputs:
%  symbols - {cell nRow x nCols} cell array of strings to layout
% Options:
%  fontSize
%  fig - [1 x 1] handle to the figure to draw in
% Outputs:
%  hdls -- [nRow x nCols] set of handles to the text elements
opts=struct('fontSize',[],'relfontSize',.1,'fig',[],'interBoxGap',.01);
opts=parseOpts(opts,varargin);
% prepare figure
if ( ~isempty(opts.fig) ) figure(opts.fig); else opts.fig=gcf; end;
% set the axes to invisible
set(gcf,'color',[0 0 0],'toolbar','none','menubar','none'); set(gca,'visible','off');
set(gca,'YDir','reverse');
set(gca,'xlim',[0 1],'ylim',[0 1],'xtick',[],'ytick',[]);
set(gca,'position',[.07 .07 .86 .86]);

% compute the fontsize in pixels
set(opts.fig,'Units','pixel');
wSize=get(opts.fig,'position');
opts.fontSize = opts.relfontSize*wSize(4);

% init the symbols
hdls   =zeros([size(symbols),1]);
w = 1/(size(symbols,1)); h=1/(size(symbols,2));
for i = 1:size(symbols,1)
  for j = 1:size(symbols,2)
    x=j*w-.5*w; y=i*h-.5*h; % center of the box
    rect = [x-.5*w+opts.interBoxGap,y-.5*h+opts.interBoxGap,w-2*opts.interBoxGap,h-2*opts.interBoxGap];
    hdls(i,j,1) = ...
        text(x,y+.2*h,symbols{i,j},...
             'FontUnits','pixel','fontsize',opts.fontSize,'HorizontalAlignment','center','FontWeight','bold','Color',[.1 .1 .1]);
  end
end
drawnow;
return;
function testCase()
grid=initGrid({'1' '2';'3' '4'},[]);
