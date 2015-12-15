set batdir=%~dp0
cd %batdir%
call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "startSigProcBuffer;quit;" %matopts%
) else (
  echo startSigProcBuffer; | %matexe% %matopts%
)