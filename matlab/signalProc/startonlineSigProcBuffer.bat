set batdir=%~dp0
cd %batdir%
call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "onlineSigProcBuffer;quit;" %matopts%
) else (
  echo onlineSigProcBuffer; | %matexe% %matopts%
)
