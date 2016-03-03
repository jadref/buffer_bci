set batdir=%~dp0
cd %batdir%
call ..\utilities\findJava.bat

echo Starting: /buffer/java/SignalProxy.jar
%javaexe% -cp "buffer\java\BufferClient.jar;buffer\java\SignalProxy.jar" nl.dcc.buffer_bci.SignalProxy localhost:1972 %*