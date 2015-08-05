call ..\utilities\findJava.bat
set batdir=%~dp0
cd %batdir%
%javaexe% -cp "../dataAcq/buffer/java/BufferClient.jar;build\jar\CursorStim.jar" nl.ru.dcc.buffer_bci.CursorStim
