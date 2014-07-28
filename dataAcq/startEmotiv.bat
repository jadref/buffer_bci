set batdir=%~dp0
set drive=%~d0
rem Search for the buffer executable
if exist "%batdir%buffer\bin\win32\emotiv2ft.exe" ( set buffexe="%batdir%buffer\bin\win32\emotiv2ft.exe" )
if exist "%batdir%buffer\win32\emotiv2ft.exe" ( set buffexe="%batdir%buffer\win32\emotiv2ft.exe" )
if exist "%batdir%emotiv2ft.exe" ( set buffexe="%batdir%emotiv2ft.exe" )
start /b "buffer" %buffexe% emotiv.cfg localhost 1972