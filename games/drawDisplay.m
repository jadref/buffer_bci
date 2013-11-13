function [maph,agentsh,scoreh]=drawDisplay(map,maph,agents,agentsh,score,scoreh,move,moveh)
% draw the map as a bitmap
%set(maph,'Cdata',map);
% draw the agents as a bitmap with alpha-value
%set(agentsh,'CData',agents,'alphaData',agents>0);
% draw the score at the top
set(scoreh,'String',sprintf('Score : %d',score));
set(moveh,'String',sprintf('Moves : %d',move));
