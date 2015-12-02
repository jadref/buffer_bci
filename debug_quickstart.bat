setlocal enabledelayedexpansion
set batdir=%~dp0

set dataacq=%1
if "%dataacq%"=="" ( 
set dataacq=java
)

echo Starting the non-saving java buffer server \(background\)
rem wmic process call create "dataAcq/startJavaNoSaveBuffer.bat" | find "ProcessId"
start dataAcq\startJavaNoSaveBuffer.bat

rem Weird windows hack to sleep for 2 secs to allow the buffer server to start
ping 127.0.0.1 -n 3 > nul


echo Starting the data acquisation device %dataacq% \(background\)
if "%dataacq%"=="audio" (
  start dataAcq\startJavaAudio.bat localhost 2
) else if "%dataacq%"=="matlab" (
  start dataAcq\startMatlabSignalProxy.bat
) else (
  start dataAcq\startJavaSignalproxy.bat
)
rem dataacqpid=$!


echo dataacqpid=$dataacqpid
echo Starting the default signal processing function \(background\)
start  .\signalProc\startSigProcBuffer.bat
rem sigprocpid=$!


echo Starting the event viewer
dataAcq\startJavaEventViewer.bat

rem Cleanup all the processes we started
rem TODO: make this work, getting the pid of started process seems very hard in windows....
rem taskkill /pid %bufferpid%
rem taskkill /pid %dataacqpid%
rem taskkill /pid %sigprocpid%
