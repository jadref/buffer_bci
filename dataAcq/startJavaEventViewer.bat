set batdir=%~dp0
cd %batdir%
call ..\utilities\findJava.bat
echo Starting: %javaexe% buffer/java/eventViewer.class
%javaexe% -cp "buffer/java/BufferClient.jar;buffer/java" EventViewer %*
