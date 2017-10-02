set batdir=%~dp0
cd %batdir%
call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Batch - Matlab" /b %matexe% -r "batchSigProcBuffer;quit;" %matopts%
  start "Online - Matlab" /b %matexe% -r "onlineSigProcBuffer;quit;" %matopts%
) else (
  echo batchSigProcBuffer; | start "Batch - Ovtave" /b %matexe% %matopts%
  echo onlineSigProcBuffer; | start "Online - Ovtave" /b %matexe% %matopts%  
)
