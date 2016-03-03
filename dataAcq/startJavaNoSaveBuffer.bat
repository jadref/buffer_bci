set batdir=%~dp0
cd %batdir%
call ..\utilities\findJava.bat

echo Starting: %javaexe% buffer/java/BufferServer.jar 1972
%javaexe% -jar "buffer/java/BufferServer.jar" 1972 %*
