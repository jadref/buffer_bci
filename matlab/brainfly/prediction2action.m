function [cannonAction,cannonTrotFrac]=prediction2action(prob,margin,warpp)
  if( nargin<2 || isempty(margin) ) margin=.1; end;
  if( nargin<3 || isempty(warpp) ) warpp=false; end;
  cannonAction=''; cannonTrotFrac=[];
  if( isempty(prob) )  return; end;
  % assume class order: [right left fire] (if fire is present)
  if( warpp ) % warp = prod=position
    cannonAction=prob(1);
    if( numel(prob)<=2 )   cannonAction = prob(1);
    elseif(numel(prob)>2)  cannonAction = prob(1)./sum(prob(1:2));
    end;
  else % discrete steps
    cannonTrotFrac=.4; % Meh speed
    if( prob(1)>prob(2)+margin ) cannonAction='right'; end;
    if( prob(2)>prob(1)+margin ) cannonAction='left'; end;
  end
  if( numel(prob)>2 && prob(3)==100) cannonAction='fire'; end;
end
