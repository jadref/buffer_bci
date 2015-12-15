set batdir=%~dp0
rem Search for the buffer executable
if exist "%batdir%buffer\bin\win32\demo_buffer.exe" ( set buffexe="%batdir%buffer\bin\win32\demo_buffer.exe" )
if exist "%batdir%buffer\win32\demo_buffer.exe" ( set buffexe="%batdir%buffer\win32\demo_buffer.exe" )
if exist "%batdir%buffer\bin\win32\demo_buffer_unix.exe" ( set buffexe="%batdir%buffer\bin\win32\demo_buffer_unix.exe" )
if exist "%batdir%buffer\win32\demo_buffer_unix.exe" ( set buffexe="%batdir%buffer\win32\demo_buffer_unix.exe" )
if exist "%batdir%demo_buffer_unix.exe" ( set buffexe="%batdir%demo_buffer_unix.exe" )
start /b "buffer" %buffexe% %*
