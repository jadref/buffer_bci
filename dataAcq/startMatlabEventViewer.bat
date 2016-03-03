set batdir=%~dp0
cd %batdir%
call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "run ../matlab/utilities/initPaths.m;eventViewer();quit;" %matopts%
) else (
  echo run ../matlab/utilities/initPaths.m;eventViewer;quit; | %matexe% %matopts%
)
