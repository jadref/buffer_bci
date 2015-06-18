call ..\utilities\findJava.bat
set batdir=%~dp0

echo Starting: %javaexe% %batdir%/buffer/java/eventViewer.class
%javaexe% -cp "%batdir%/buffer/java/BufferClient.jar;%batdir%/buffer/java" eventViewer
