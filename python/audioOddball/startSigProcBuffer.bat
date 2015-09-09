call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "run ../../utilities/initPaths.m;startSigProcBuffer('epochEventType','stimulus.target','freqband',[.1 .3 20 25],'clsfr_type','erp','trlen_ms',1000);" %matopts%
) else (
  echo run ../../utilities/initPaths.m;startSigProcBuffer('epochEventType','stimulus.target','freqband',[.1 .3 20 25],'clsfr_type','erp','trlen_ms',1000); | %matexe% %matopts%
)
