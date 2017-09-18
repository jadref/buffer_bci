  %==========================================================================
function str = genTextStr(score,curBalls,cannonKills)
  str = sprintf(['  Shots: %i  |  hits: %i  |  acc.:%.1f%%'...
                   '  |  bonus: %i  |  Died  %i times.']...
                ,score.shots,score.hits,100*score.hits/max(1,score.shots)...
                ,score.bonushits,cannonKills);
end