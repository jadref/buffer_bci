function [cannonAction,cannonTrotFrac]=prediction2action(prob,margin)
  % assume class order: [left right fire] (if fire is present)
  cannonAction='';
  cannonTrotFrac=.4; % Meh speed
  if ( nargin<2 || isempty(margin) ) margin=.1; end;
  if( isempty(prob) )  return; end;
  if( prob(1)>prob(2)+margin ) cannonAction='left'; end;
  if( prob(2)>prob(1)+margin ) cannonAction='right'; end;
  if( prob(3)==100) cannonAction='fire'; end;
  %if( numel(prob)>2 && prob(3)>max(prob(1:2)) ) cannonAction='fire'; end;
end
