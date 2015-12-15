set batdir=%~dp0
call %batdir%\..\utilities\findJava.bat
echo Starting : %batdir%\buffer\java\syncGenerator
%javaexe% -cp "%batdir%\buffer\java\BufferClient.jar;%batdir%\buffer\java\SyncGenerator.jar" nl.dcc.buffer_bci.SyncGenerator localhost:1972 localhost:1973 %*
