call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "runGame;quit;" %matopts%
) else (
  echo runGame;quit; | %matexe% %matopts%
)