% Create all stimuli necessary for the movementBCI game
function [fixcross,msgh,scoreh,feedback,fig,pileh] = init_stim(neutralColor,textColor)

    clf;
    fig=gcf;
    set(fig,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
    set(fig,'Units','pixel');wSize=get(fig,'position');fontSize = .05*wSize(4);
    axes('position',[0 0 1 1],'visible','off','xlim',[0 1],'ylim',[0 1],'nextplot','add','color',[0 0 0]);

    pileh=rectangle('position',[0.47 0.47 0.05 0.05],'curvature',[1 1],'facecolor',neutralColor,'visible','off'); % position = [x y width height]

    % fix pos score
    fixcross=text(.5,.5,'+','HorizontalAlignment','center','VerticalAlignment','middle',...
        'FontUnits','pixel','fontsize',.05*wSize(4),'color',textColor,'visible','off');
    msgh=text(.5,.53,'+','HorizontalAlignment','center','VerticalAlignment','middle',...
        'FontUnits','pixel','fontsize',.05*wSize(4),'color',textColor,'visible','off');
    scoreh=text(0,1,'','HorizontalAlignment','left','verticalAlignment','top',...
        'FontUnits','pixel','fontsize',.1*wSize(4),'color',textColor,'visible','off');
    feedback=text(.5,.53,'+','HorizontalAlignment','center','VerticalAlignment','middle',...
        'FontUnits','pixel','fontsize',.05*wSize(4),'color',textColor,'visible','off');
end