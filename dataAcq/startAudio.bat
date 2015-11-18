set batdir=%~dp0
cd %batdir%
rem Search for the executable
set execname=audio2ft
if exist "%batdir%buffer\bin\win32\%execname%.exe" ( set buffexe="%batdir%buffer\bin\win32\%execname%.exe" )
if exist "%batdir%buffer\win32\%execname%.exe" ( set buffexe="%batdir%buffer\win32\%execname%.exe" )
if exist "%batdir%%execname%.exe" ( set buffexe="%batdir%%execname%.exe" )

rem audio2ft deviceID host port
rem N.B. config paramters from audio.cfg in this directory
start /b "%execname%" %buffexe% 0 localhost 1972 %*