call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "runbki323;quit;" %matopts%
) else (
  echo runbki323;quit; | %matexe% %matopts%
)
