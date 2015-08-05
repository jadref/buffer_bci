call ..\utilities\findJava.bat
set batdir=%~dp0

%javaexe% -cp "%batdir%/lib/BufferServer.jar;%batdir%/build/jar/CursorStim.jar" nl.ru.dcc.buffer_bci.CursorStim
