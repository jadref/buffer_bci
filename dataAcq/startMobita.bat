set batdir=%~dp0
rem Search for the buffer executable
if exist "%batdir%buffer\bin\win32\mobita2ft.exe" ( set buffexe="%batdir%buffer\bin\win32\mobita2ft.exe" )
if exist "%batdir%buffer\win32\mobita2ft.exe" ( set buffexe="%batdir%buffer\win32\mobita2ft.exe" )
if exist "%batdir%mobita2ft.exe" ( set buffexe="%batdir%mobita2ft.exe" )
rem First setup windows to allow connection to ad-hoc network
set mobitaNetwork=Mobita_0710120016
rem netsh wlan set hostednetwork mode=allow ssid="%mobitaNetwork" key="MOBITA0120016"
rem netsh wlan start %mobitaNetwork%
start /b "mobita2ft" %buffexe% 10.11.12.13:4242 localhost:1972 50 4
rem netsh wlan stop %mobitaNetwork%
