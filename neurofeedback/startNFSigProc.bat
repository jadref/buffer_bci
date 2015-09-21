call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "startNFSigProc();quit;" %matopts%
) else (
  echo startNFSigProc;quit; | %matexe% %matopts%
)
