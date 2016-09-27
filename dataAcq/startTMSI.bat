set batdir=%~dp0
rem Search for the buffer executable
if exist "%batdir%buffer\bin\win32\tmsi2ft.exe" ( set buffexe="%batdir%buffer\bin\win32\tmsi2ft.exe" )
if exist "%batdir%buffer\win32\tmsi2ft.exe" ( set buffexe="%batdir%buffer\win32\tmsi2ft.exe" )
if exist "%batdir%tmsi2ft.exe" ( set buffexe="%batdir%tmsi2ft.exe" )
start /b "buffer" %buffexe% tmsi.cfg localhost 1972 %*
