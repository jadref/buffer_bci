call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "cd ..\matrixSpeller;startSigProcBuffer;quit;" %matopts%
) else (
  echo startSigProcBuffer | %matexe% %matopts%
)