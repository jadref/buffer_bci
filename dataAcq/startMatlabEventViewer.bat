call ..\utilities\findMatlab.bat
set batdir=%~dp0
cd %batdir%
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "../matlab/utilities/initPaths.m;eventViewer();quit;" %matopts%
) else (
  echo run ../matlab/utilities/initPaths.m;eventViewer;quit; | %matexe% %matopts%
)
