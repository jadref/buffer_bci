run(fullfile(fileparts(mfilename('fullpath')),'matlab','utilities','initPaths.m'));
startJavaBuffer();

try;
   % add the jar for the signal proxy
   sigproxjar=fullfile(dataAcq_dir,'buffer','java','SignalProxy.jar');
   if ( exist(sigproxjar,'file') )
      javaaddpath(sigproxjar);
      sigprox=javaObject('nl.dcc.buffer_bci.SignalProxy');
      sigprox.start();
   end
catch;
   buffer_signalproxy();
end