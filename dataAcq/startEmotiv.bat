set batdir=%~dp0
set drive=%~d0
rem Search for the buffer executable
set execname=emotiv2ft
if exist "%batdir%buffer\bin\win32\%execname%.exe" ( set buffexe="%batdir%buffer\bin\win32\%execname%.exe" )
if exist "%batdir%buffer\win32\%execname%.exe" ( set buffexe="%batdir%buffer\win32\%execname%.exe" )
if exist "%batdir%%execname%.exe" ( set buffexe="%batdir%%execname%.exe" )
start /b "%execname%" %buffexe% emotiv.cfg localhost 1972 %*