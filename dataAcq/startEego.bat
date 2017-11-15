set batdir=%~dp0
cd %batdir%
rem Search for the buffer executable
set exename=eego2ft
if exist "buffer\bin\win32\%exename%.exe" ( set buffexe="buffer\bin\win32\%exename%.exe" )
if exist "buffer\win32\%exename%.exe" ( set buffexe="buffer\win32\%exename%.exe" )
if exist "%exename%.exe" ( set buffexe="%exename%.exe" )
start /b "eego2ft" %buffexe% eego.cfg localhost 1972 %*
