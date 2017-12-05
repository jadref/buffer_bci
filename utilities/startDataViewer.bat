set batdir=%~dp0
cd %batdir%
call ..\utilities\findMatlab.bat
cd ..\matlab\utilities
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "dataViewer();quit()" %matopts%
) else (
  echo  dataViewer;quit | %matexe% %matopts%
)
