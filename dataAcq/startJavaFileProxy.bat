set batdir=%~dp0
call %batdir%\..\utilities\findJava.bat
echo Starting: %batdir%/buffer/java/FilePlayback.jar %*
java -cp "%batdir%buffer\java\BufferClient.jar;%batdir%buffer\java\FilePlayback.jar" nl.dcc.buffer_bci.FilePlayback %*
