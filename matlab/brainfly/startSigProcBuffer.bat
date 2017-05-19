call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "configAndStartSigProcBuffer;quit;" %matopts%
) else (
echo configAndStartSigProcBuffer;quit; | %matexe% %matopts%
)
