function [feedback,correct_time]=initfeedback(correct_time,t_move, square, startsize, fastColor, slowColor, neutralColor)

if t_move < 3
    feedback=set(square,'position',[.5-startsize/2 .5-startsize/2 startsize startsize],'facecolor',fastColor,'visible','on');
elseif t_move > 12
    feedback=set(square,'position',[.5-startsize/2 .5-startsize/2 startsize startsize],'facecolor',slowColor,'visible','on');
else
    feedback=set(square,'position',[.5-startsize/2 .5-startsize/2 startsize startsize],'facecolor',neutralColor,'visible','on');
    correct_time=correct_time+1;
end
end