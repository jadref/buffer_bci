setlocal enabledelayedexpansion
set batdir=%~dp0
rem Search for the executable
if exist "%batdir%buffer\bin\win32\eventViewer.exe" ( set buffexe="%batdir%buffer\bin\win32\eventViewer.exe" )
if exist "%batdir%buffer\win32\eventViewer.exe" ( set buffexe="%batdir%buffer\win32\eventViewer.exe" )
if exist "%batdir%eventViewer.exe" ( set buffexe="eventViewer.exe" )
start /b "eventViewer" %buffexe% %*
