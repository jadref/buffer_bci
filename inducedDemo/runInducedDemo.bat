call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "runInducedDemo;quit;" %matopts%
) else (
  echo runInducedDemo | %matexe% %matopts%
)