set batdir=%~dp0
cd %batdir%
call ..\utilities\findMatlab.bat
cd %~dp0
cd ..\matlab\utilities
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "sigViewer();quit()"  
) else (
  echo  sigViewer;quit | %matexe% %matopts%
)
