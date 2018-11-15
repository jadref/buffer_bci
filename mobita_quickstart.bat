setlocal enabledelayedexpansion
set batdir=%~dp0
cd %batdir%\dataAcq

echo Starting the java buffer server \(background\)
rem wmic process call create "dataAcq/startJavaNoSaveBuffer.bat" | find "ProcessId"
start startJavaBuffer.bat

rem Weird windows hack to sleep for 2 secs to allow the buffer server to start
ping 127.0.0.1 -n 3 > nul

echo Starting the data acquisation device %dataacq% \(background\)
start startMobita.bat
rem dataacqpid=$!

echo Starting the event viewer
startJavaEventViewer.bat

rem Cleanup all the processes we started
rem TODO: make this work, getting the pid of started process seems very hard in windows....
rem taskkill /pid %bufferpid%
rem taskkill /pid %dataacqpid%
rem taskkill /pid %sigprocpid%
