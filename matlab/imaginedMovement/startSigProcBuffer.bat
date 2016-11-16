call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "imstartSigProcBuffer;quit;" %matopts%
) else (
echo imstartSigProcBuffer;quit; | %matexe% %matopts%
)
