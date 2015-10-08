call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "configureNF;nfStartSigProcBuffer();quit;" %matopts%
) else (
  echo configureNF;nfStartSigProcBuffer;quit; | %matexe% %matopts%
)
