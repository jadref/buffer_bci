call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "../utilities/initPaths.m;erpViewer();quit;" %matopts%
) else (
  echo run ../utilities/initPaths.m;erpViewer;quit; | %matexe% %matopts%
)
