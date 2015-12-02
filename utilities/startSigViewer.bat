set batdir=%~dp0
cd %batdir%
call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "sigViewer();quit()"  
) else (
  echo  sigViewer;quit | %matexe% %matopts%
)
