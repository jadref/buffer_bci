set batdir=%~dp0
rem Search for the buffer executable
if exist "%batdir%buffer\bin\win32\thinkgear2ft.exe" ( set buffexe="%batdir%buffer\bin\win32\thinkgear2ft.exe" )
if exist "%batdir%buffer\win32\thinkgear2ft.exe" ( set buffexe="%batdir%buffer\win32\thinkgear2ft.exe" )
if exist "%batdir%thinkgear2ft.exe" ( set buffexe="%batdir%thinkgear2ft.exe" )
rem start /b "buffer" %buffexe% %1 %2 %3
start /b "Mindwave2FT" /HIGH %buffexe% com6 mindwave.cfg localhost 1972 %*