%==========================================================================
function [cannonAction,cannonTrotFrac]=key2action(curKeyLocal)
  
      %----------------------------------------------------------------------
      %----------------------------------------------------------------------
      % This section needs to produce two variables: cannonTrotFrac and
      % cannonTrotFrac.
  
  cannonAction   = [];
  cannonTrotFrac = [];
  if ( isempty(curKeyLocal) ) return; end;
  
                                % Determine speed:
  switch curKeyLocal
         
    case {'z','slash','/'} % super fast!
      cannonTrotFrac = 1;
      
    case {'x','period','.'} % fast
      cannonTrotFrac = 0.8;
      
    case {'c','comma',','} % meh
      cannonTrotFrac = 0.6;
      
    case {'v','m'} % slow
      cannonTrotFrac = 0.4;
      
    case {'b','n'} % slooow
        cannonTrotFrac = 0.2;
  end
  
                                % Determine the correct action:
  switch curKeyLocal
         
    case {'z','x','c','v','b'}
      cannonAction = 'left';
      
    case {'n','m','comma','period','slash',',','.','/'}
      cannonAction = 'right';
      
    case {'space',' '}
      cannonAction = 'fire';
  end
end
