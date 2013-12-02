% set the real-time-clock to use
global getwTime;
evalin('caller','global getwTime');
evalin('base','global getwTime');
if ( isempty(getwTime) && exist('GetSecs') )
  try % PTB method may break!
    GetSecs();
    getwTime=@GetSecs;    
  catch
  end
end
if ( isempty(getwTime) )
  if ( exist('java')==2 ) % use the best clock we've got available
                        % N.B. *have* to use javaMethod ... so works when java isn't available
    if ( exist('OCTAVE_VERSION') )
    try 
      javaMethod('nanoTime','java.lang.System');
      getwTime=@() javaMethod('nanoTime','java.lang.System').doubleValue()/1000/1000/1000; % only in newer java's
    catch
      getwTime=@() javaMethod('currentTimeMillis','java.lang.System').doubleValue()/1000;
    end
    else
    try 
      javaMethod('nanoTime','java.lang.System');
      getwTime=@() javaMethod('nanoTime','java.lang.System')/1000/1000/1000; % only in newer java's
    catch
      getwTime=@() javaMethod('currentTimeMillis','java.lang.System')/1000;
    end
    end
  else
    getwTime=@() clock()*[0 0 86400 3600 60 1]'; % in seconds
  end
end
