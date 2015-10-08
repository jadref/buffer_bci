call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "runSpeller;quit;" %matopts%
) else (
  echo runSpeller | %matexe% %matopts%
)