call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "runSSEP;quit;" %matopts%
) else (
  echo runSSEP;quit; | %matexe% %matopts%
)