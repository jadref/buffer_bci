call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "runNF;quit;" %matopts%
) else (
  echo runNF;quit; | %matexe% %matopts%
)