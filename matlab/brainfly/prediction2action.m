  %==========================================================================
function [cannonAction,cannonTrotFrac]=prediction2action(prob)
           % assume class order: [left right fire] (if fire is present)
  cannonAction='';
  cannonTrotFrac=.4; % Meh speed
  if( isempty(prob) )  return; end;
  margin=.1;
  if( prob(1)>prob(2)+margin ) cannonAction='left'; end;
  if( prob(2)>prob(1)+margin ) cannonAction='right'; end;
  if( numel(prob)>2 && prob(3)>max(prob(1:2)) ) cannonAction='fire'; end;
end
