set batdir=%~dp0
call %batdir%\..\utilities\findJava.bat
echo Starting: %javaexe% %batdir%/buffer/java/eventViewer.class
%javaexe% -cp "%batdir%/buffer/java/BufferClient.jar;%batdir%/buffer/java" EventViewer %*
