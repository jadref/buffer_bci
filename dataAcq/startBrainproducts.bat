set batdir=%~dp0
rem Search for the buffer executable
if exist "%batdir%buffer\bin\win32\rda2ft.exe" ( set buffexe="%batdir%buffer\bin\win32\rda2ft.exe" )
if exist "%batdir%buffer\win32\rda2ft.exe" ( set buffexe="%batdir%buffer\win32\rda2ft.exe" )
if exist "%batdir%rda2ft.exe" ( set buffexe="%batdir%rda2ft.exe" )
rem start /b "buffer" %buffexe% %1 %2 %3
start /b "rda2ft" %buffexe% localhost 51244 - 1972 %*