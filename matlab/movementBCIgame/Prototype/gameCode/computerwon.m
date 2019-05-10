% Set stimuli in case computer won
function computerwon(current_score, t_computer, fig, pileh, msgh, fixcross, compWinsColor, feedbackColor)
    set(pileh,'facecolor',compWinsColor);
    set(msgh,'string',{'Too Slow!!!'},'color',feedbackColor,'visible','on');
    set(fixcross,'string',{sprintf('%3.1f',current_score)},'visible','on','color',feedbackColor);
    drawnow;
    sleepSec(1);
    set(msgh,'string',{'Too Slow!!!'},'color',feedbackColor,'visible','on');
    set(fixcross,'string','+','visible','on','color',feedbackColor);
end