  %==========================================================================
function str = genTextStr(score)
  str = sprintf(' Time Remaining: %4.1f s |  Points Possible: %4.0f'...
                ,score.timetogo,score.pointspossible);
end
