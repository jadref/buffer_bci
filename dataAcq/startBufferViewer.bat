set batdir=%~dp0
set drive=%~d0
rem Search for the buffer viewer executable
if exist "%batdir%buffer\bin\win32\bufferViewer.exe" ( set buffexe="%batdir%buffer\bin\win32\bufferViewer.exe" )
if exist "%batdir%buffer\win32\bufferViewer.exe" ( set buffexe="%batdir%buffer\win32\bufferViewer.exe" )
if exist "%batdir%bufferViewer.exe" ( set buffexe="%batdir%bufferViewer.exe" )
start /b "bufferViewer" %buffexe%
