set batdir=%~dp0
cd %batdir%
call ..\utilities\findJava.bat
echo Starting: /buffer/java/AudioToBuffer.jar
%javaexe% -cp "buffer\java\BufferClient.jar;buffer\java\AudioToBuffer.jar" nl.dcc.buffer_bci.AudioToBuffer localhost:1972 441 %*
