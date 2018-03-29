function [msgh,square,fig]=init_stim(neutralColor,textColor)
clf;
fig=gcf;
set(fig,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
set(fig,'Units','pixel');wSize=get(fig,'position');fontSize = .05*wSize(4);
axes('position',[0 0 1 1],'visible','off','xlim',[0 1],'ylim',[0 1],'nextplot','add','color',[0 0 0]);

square=rectangle('position',[.5 .5 .5 .5],'curvature',[0 0],'facecolor',neutralColor,'visible','off'); % position = [x y width height]
msgh=text(.5,.5,'+','HorizontalAlignment','center','VerticalAlignment','middle',...
    'FontUnits','pixel','fontsize',.05*wSize(4),'color',textColor,'visible','off');

end