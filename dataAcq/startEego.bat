set batdir=%~dp0
rem Search for the buffer executable
set exename=eego2ft
if exist "%batdir%buffer\bin\win32\%exename%.exe" ( set buffexe="%batdir%buffer\bin\win32\%exename%.exe" )
if exist "%batdir%buffer\win32\%exename%.exe" ( set buffexe="%batdir%buffer\win32\%exename%.exe" )
if exist "%batdir%\%exename%.exe" ( set buffexe="%batdir%\%exename%.exe" )
start /b "eego2ft" %buffexe% eego.cfg localhost 1972 %*
