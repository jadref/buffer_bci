call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "configureGame;startSigProcBuffer;quit;" %matopts%
) else (
echo configureGame;startSigProcBuffer;quit; | %matexe% %matopts%
)
