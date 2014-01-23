set batdir=%~dp0
rem Search for the buffer executable
if exist "%batdir%buffer\bin\win32\mobita2ft.exe" ( set buffexe="%batdir%buffer\bin\win32\mobita2ft.exe" )
if exist "%batdir%buffer\win32\mobita2ft.exe" ( set buffexe="%batdir%buffer\win32\mobita2ft.exe" )
if exist "%batdir%mobita2ft.exe" ( set buffexe="%batdir%mobita2ft.exe" )
rem start /b "buffer" %buffexe% %1 %2 %3
start /b "buffer" %buffexe% 10.11.12.13:4242 localhost:1972 50 4