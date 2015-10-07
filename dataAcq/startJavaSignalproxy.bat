call ..\utilities\findJava.bat
set batdir=%~dp0
echo Starting: /buffer/java/SignalProxy.jar
%javaexe% -cp "%batdir%/buffer/java/BufferClient.jar:%batdir%/buffer/java/SignalProxy.jar" nl.dcc.buffer_bci.SignalProxy