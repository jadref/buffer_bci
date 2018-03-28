% Set stimuli in case human won
function humanwon(current_score, fig, pileh, msgh, fixcross, humanWinsColor, feedbackColor)
    set(pileh,'facecolor',humanWinsColor);
    set(msgh,'string',{'You Win!!!'},'color',feedbackColor,'visible','on');
    set(fixcross,'string',{sprintf('%3.1f',current_score)},'visible','on','color',feedbackColor);
    drawnow;
    sleepSec(1);
    set(msgh,'string',{'You Win!!!'},'color',feedbackColor,'visible','on');
    set(fixcross,'string','+','visible','on','color',feedbackColor);
end

