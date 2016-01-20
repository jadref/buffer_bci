set batdir=%~dp0
cd %batdir%
call ..\utilities\findJava.bat
echo Starting: buffer/java/FilePlayback.jar %*
%javaexe% -cp "buffer\java\BufferClient.jar;buffer\java\FilePlayback.jar" nl.dcc.buffer_bci.FilePlayback %*
