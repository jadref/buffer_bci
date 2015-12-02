set batdir=%~dp0
call %batdir%\..\utilities\findJava.bat

echo Starting: /buffer/java/SignalProxy.jar
%javaexe% -cp "%batdir%buffer\java\BufferClient.jar;%batdir%buffer\java\SignalProxy.jar" nl.dcc.buffer_bci.SignalProxy localhost:1972 %*