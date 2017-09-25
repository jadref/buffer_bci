call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "configAndStartBatchSigProcBuffer;quit;" %matopts%
) else (
  echo configAndStartBatchSigProcBuffer;quit; | start "Octave" /b %matexe% %matopts%
)
