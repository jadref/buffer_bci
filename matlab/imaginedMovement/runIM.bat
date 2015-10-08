call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "runIM;quit;" %matopts%
) else (
  echo runIM;quit; | %matexe% %matopts%
)