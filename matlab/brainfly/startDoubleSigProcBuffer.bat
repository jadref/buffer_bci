call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "configAndStartBatchSigProcBuffer;quit;" %matopts%
  start "Matlab" /b %matexe% -r "configAndStartOnlineSigProcBuffer;quit;" %matopts%
) else (
  echo configAndStartBatchSigProcBuffer;quit; | start "Octave" /b %matexe% %matopts%
  echo configAndStartOnlineSigProcBuffer;quit; | start "Octave" /b %matexe% %matopts%
)
