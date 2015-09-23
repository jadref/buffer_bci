call ..\utilities\findJava.bat
set batdir=%~dp0

echo Starting: %javaexe% %batdir%/buffer/java/BufferServer.jar 1972
%javaexe% -jar "%batdir%/buffer/java/BufferServer.jar" 1972
