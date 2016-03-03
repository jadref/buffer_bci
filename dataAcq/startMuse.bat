set batdir=%~dp0
call %batdir%\..\utilities\findJava.bat
rem Start the osc2ft shim to transfer osc messages to the buffer
set oscport=1234
set oscdevice=6B38
start "osc2ft" %javaexe% -cp "%batdir%/buffer/java/BufferClient.jar;%batdir%/osc/JavaOSC.jar;%batdir%/osc" osc2ft /muse/eeg:%oscport% localhost:1972 4 220 1 10
rem Search for the buffer executable
set execname=muse-io
if exist "%batdir%buffer\bin\win32\%execname%" ( set buffexe="%batdir%buffer\bin\win32\%execname%.exe" )
if exist "%batdir%buffer\win32\%execname%.exe" ( set buffexe="%batdir%buffer\win32\%execname%.exe" )
if exist "%batdir%%execname%.exe" ( set buffexe="%batdir%%execname%.exe" )
rem start /b "buffer" %buffexe% %1 %2 %3
%buffexe% --preset 10 --50hz --osc osc.udp://localhost:%oscport%
rem %buffexe% --device %oscdevice% --preset ab --50hz --osc osc.udp://localhost:%oscport%
rem Give more helpful error message for partially installed system
if errorlevel 1 (
	start cmd /c "echo Muse-io couldn't start, have you run vcredist?\n dataAcq/buffer/win32/vcredist_x86.exe? && pause"
)
