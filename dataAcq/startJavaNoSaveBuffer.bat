set batdir=%~dp0
call %batdir%\..\utilities\findJava.bat

echo Starting: %javaexe% %batdir%/buffer/java/BufferServer.jar 1972
%javaexe% -jar "%batdir%/buffer/java/BufferServer.jar" 1972 %*
