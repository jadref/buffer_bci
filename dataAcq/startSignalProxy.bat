setlocal enabledelayedexpansion
set batdir=%~dp0
rem Search for the executable
if exist "%batdir%buffer\bin\win32\csignalproxy.exe" ( set buffexe="%batdir%buffer\bin\win32\csignalproxy.exe" )
if exist "%batdir%buffer\win32\csignalproxy.exe" ( set buffexe="%batdir%buffer\win32\csignalproxy.exe" )
if exist "%batdir%csignalproxy.exe" ( set buffexe="csignalproxy.exe" )
start /b "signalproxy" %buffexe% %*
