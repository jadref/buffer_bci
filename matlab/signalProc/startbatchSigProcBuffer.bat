set batdir=%~dp0
cd %batdir%
call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "batchSigProc;quit;" %matopts%
) else (
  echo batchSigProc; | %matexe% %matopts%
)
