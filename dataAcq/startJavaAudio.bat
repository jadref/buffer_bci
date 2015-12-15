set batdir=%~dp0
call %batdir%\..\utilities\findJava.bat
echo Starting: /buffer/java/AudioToBuffer.jar
%javaexe% -cp "%batdir%buffer\java\BufferClient.jar;%batdir%buffer\java\AudioToBuffer.jar" nl.dcc.buffer_bci.AudioToBuffer localhost:1972 441 %*
