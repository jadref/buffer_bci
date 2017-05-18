call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "runBrainfly;quit;" %matopts%
) else (
  echo runBrainfly;quit; | %matexe% %matopts%
)
