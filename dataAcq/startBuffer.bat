setlocal enabledelayedexpansion
set batdir=%~dp0
set drive=%~d0
set bciroot=output
set subject=test
rem get date/session
For /f "tokens=1-3 delims=/-. " %%a in ('date /t') do (set session=%%c%%b%%a) 
rem get time
For /f "tokens=1-4 delims=: " %%a in ('time /t') do (set block=%%a%%b%%c)
set pyfolder=dummy
if exist %batdir%\getBufferSaveDir.py (
	rem check if python is installed in path
	for %%X in (python.exe) do (set FOUND=%%~$PATH:X)
	if defined FOUND (
	  rem This is a horrible hack to get the output of the sub-command into a variable
  	  For /f "usebackq delims=" %%o in (`%batdir%\getBufferSaveDir.py`) do (set pyfolder=%%o)
	)
) 
if %pyfolder%==dummy ( 
    echo Default location
	mkdir "%drive%\%bciroot%\%subject%"
	mkdir "%drive%\%bciroot%\%subject%\%session%"
	mkdir "%drive%\%bciroot%\%subject%\%session%\%block%"
	set folder="%drive%\%bciroot%\%subject%\%session%\%block%"
) ELSE (
    echo Python location
	set folder=%pyfolder%
)
if exist "%folder%\raw_buffer" ( 
	set folder=%folder%_1
	mkdir %folder%_1	
)

rem Search for the buffer executable
if exist "%batdir%buffer\bin\win32\recording.exe" (set buffexe="%batdir%buffer\bin\win32\recording.exe" )
if exist "%batdir%buffer\win32\recording.exe" (set buffexe="%batdir%buffer\win32\recording.exe" )
if exist "%batdir%buffer\bin\recording.exe" (set buffexe="%batdir%buffer\bin\recording.exe" )
if exist "%batdir%recording.exe" ( set buffexe="%batdir%recording.exe" )
start /b "buffer" %buffexe% %folder%\raw_buffer %*
