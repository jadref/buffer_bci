set batdir=%~dp0
cd %batdir%
call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "run ../utilities/initPaths.m;eegViewer();quit;" %matopts%
) else (
  echo run ../utilities/initPaths.m;eegViewer;quit; | %matexe% %matopts%
)
