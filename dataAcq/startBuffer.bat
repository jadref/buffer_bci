set batdir=%~dp0
set drive=%~d0
set bciroot=output\raw_buffer
set subject=test
rem get date/session
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set session=%%c%%a%%b) 
rem get time
For /f "tokens=1-4 delims=: " %%a in ('time /t') do (set block=%%a%%b%%c)
set folder="%drive%\%bciroot%\%subject%"
mkdir "%folder%"
set folder="%drive%\%bciroot%\%subject%\%session%"
mkdir "%folder%"
set folder="%drive%\%bciroot%\%subject%\%session%\%block%"
if exist "%folder%" ( set folder="%folder%_1" )
mkdir "%folder%"
rem Search for the buffer executable
if exist "%batdir%buffer\bin\win32\demo_buffer.exe" ( set buffexe="%batdir%buffer\bin\win32\demo_buffer.exe" )
if exist "%batdir%buffer\win32\demo_buffer.exe" ( set buffexe="%batdir%buffer\win32\demo_buffer.exe" )
if exist "%batdir%buffer\bin\win32\demo_buffer_unix.exe" ( set buffexe="%batdir%buffer\bin\win32\demo_buffer_unix.exe" )
if exist "%batdir%buffer\win32\demo_buffer_unix.exe" ( set buffexe="%batdir%buffer\win32\demo_buffer_unix.exe" )
if exist "%batdir%demo_buffer_unix.exe" ( set buffexe="%batdir%demo_buffer_unix.exe" )
if exist "%batdir%buffer\bin\win32\recording.exe" (set buffexe="%batdir%buffer\bin\win32\recording.exe" )
if exist "%batdir%buffer\win32\recording.exe" (set buffexe="%batdir%buffer\win32\recording.exe" )
if exist "%batdir%buffer\bin\recording.exe" (set buffexe="%batdir%buffer\bin\recording.exe" )
if exist "%batdir%recording.exe" ( set buffexe="%batdir%recording.exe" )
start /b "buffer" %buffexe% "%folder%\raw_buffer"