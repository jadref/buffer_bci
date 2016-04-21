call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "cd ..\ssep;configureSSEP;cd ..\games;startSigProcBuffer('clsfr_type','ersp','trlen_ms',trlen_ms,'trainOpts',trainOpts,'useGUI',0);" %matopts%
) else (
  echo configureSSEP;startSigProcBuffer^('clsfr_type','ersp','trlen_ms',trlen_ms,'trainOpts',trainOpts,'useGUI',0^);quit; | %matexe% %matopts%
)
