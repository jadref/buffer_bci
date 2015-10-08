function ev = init(ev)

% 0 = empty
% 1 = wall
% 2 = block
% 3 = goal
% 4 = player

% obtain initial level state from blockfile 
ev.gamestate = bs_get_blockvalue(ev,'Experiment','initstate');