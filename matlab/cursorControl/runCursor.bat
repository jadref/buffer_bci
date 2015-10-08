call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "runCursor;quit;" %matopts%
) else (
  echo runCursor | %matexe% %matopts%
)