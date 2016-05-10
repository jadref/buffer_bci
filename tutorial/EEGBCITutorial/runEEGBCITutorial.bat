call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "runEEGBCITutorial;quit;" %matopts%
) else (
  echo runEEGBCITutorial;quit; | %matexe% %matopts%
)