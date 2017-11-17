set batdir=%~dp0
cd %batdir%
call ..\utilities\findMatlab.bat
cd ..\matlab\utilities
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "sigViewer();quit()" %matopts%
) else (
  echo  sigViewer;quit | %matexe% %matopts%
)
