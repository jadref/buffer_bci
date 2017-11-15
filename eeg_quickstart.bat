setlocal enabledelayedexpansion
set batdir=%~dp0
cd %batdir%\dataAcq

set dataacq=%1
if "%dataacq%"=="" ( 
set dataacq=mobita
)
set sigproc=%2

echo Starting the java buffer server \(background\)
rem wmic process call create "dataAcq/startJavaNoSaveBuffer.bat" | find "ProcessId"
start startJavaBuffer.bat

rem Weird windows hack to sleep for 2 secs to allow the buffer server to start
ping 127.0.0.1 -n 3 > nul


echo Starting the data acquisation device %dataacq% \(background\)
if "%dataacq%"=="mobita" (
  start startMobita.bat localhost 2
) else if "%dataacq%"=="biosemi" (
  start startBiosemi.bat
) else if "%dataacq%"=="eego" (
  start startEego.bat
) else (
  echo Dont recognise the eeg device type
)
rem dataacqpid=$!

if defined sigproc (
    if "%sigproc%"=="1" (
    echo Starting the default signal processing function \(background\)
    start  ..\matlab\signalProc\startSigProcBuffer.bat
    rem sigprocpid=$!
    )
)

echo Starting the event viewer
startJavaEventViewer.bat

rem Cleanup all the processes we started
rem TODO: make this work, getting the pid of started process seems very hard in windows....
rem taskkill /pid %bufferpid%
rem taskkill /pid %dataacqpid%
rem taskkill /pid %sigprocpid%
