call ..\utilities\findJava.bat
set batdir=%~dp0
echo Starting: %batdir%/buffer/java/FilePlayback.jar $@
java -cp "%batdir%buffer\java\BufferClient.jar;%batdir%buffer\java\FilePlayback.jar" nl.dcc.buffer_bci.FilePlayback
