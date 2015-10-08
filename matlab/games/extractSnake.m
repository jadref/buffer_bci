function [snakexy]=extractSnake(map,key);
if( isstruct(map) ) map=map.map; end;
snakexy=[];
% find the head
[hi,hj]=find(map==key.snakehead);
snakexy=[hi;hj];
% track along the body
while(true)
  map(hi,hj)=0; % mark as seen
  if ( hi>0 && map(hi-1,hj)==key.snakebody )
    hi=hi-1;
  elseif ( hj>0 && map(hi,hj-1)==key.snakebody )
    hj=hj-1;
  elseif ( hi<size(map,1) && map(hi+1,hj)==key.snakebody )
    hi=hi+1;
  elseif( hj<size(map,2) && map(hi,hj+1)==key.snakebody )
    hj=hj+1;
  else % couldn't find body. must have reached the tail!
    break;
  end
  snakexy=[snakexy [hi;hj]]; % add to the snake list
end
