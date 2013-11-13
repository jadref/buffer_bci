function  [newdir]=getPacMove(map,agents,moves)
 % Random
 newdir=ceil(rand()*(numel(moves.name)-eps)+eps);
end
