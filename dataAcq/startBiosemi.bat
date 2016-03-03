set batdir=%~dp0
set drive=%~d0
set bciroot=output\raw_buffer
set subject=test
rem get date/session
For /f "tokens=2-4 delims=/- " %%a in ('date /t') do (set session=%%c%%b%%a) 
rem get time
For /f "tokens=1-4 delims=: " %%a in ('time /t') do (set block=%%a%%b%%c)
set outfile=%drive%\%bciroot%\%subject%
mkdir %outfile%
set outfile=%drive%\%bciroot%\%subject%\%session%
mkdir %outfile%
set outfile=%drive%\%bciroot%\%subject%\%session%\%block%
mkdir %outfile%
set outfile=%drive%\%bciroot%\%subject%\%session%\%block%\raw_gdf\%subject%.gdf
rem Search for the buffer executable
if exist "%batdir%buffer\bin\win32\biosemi2ft.exe" ( set buffexe="%batdir%buffer\bin\win32\biosemi2ft.exe" )
if exist "%batdir%buffer\win32\biosemi2ft.exe" ( set buffexe="%batdir%buffer\win32\biosemi2ft.exe" )
if exist "%batdir%biosemi2ft.exe" ( set buffexe="%batdir%biosemi2ft.exe" )
start /b "buffer" %buffexe% biosemi.cfg %outfile% localhost 1972 %*