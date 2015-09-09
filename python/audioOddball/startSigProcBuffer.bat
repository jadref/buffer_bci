call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "run ../../utilties/initPaths.m;startSigProcBuffer('epochEventType','stimulus.target','freqband',[.1 .3 20 25],'clsfr_type','erp','trlen_ms',trlen_ms);" %matopts%
) else (
  echo run ../../utilties/initPaths.m;startSigProcBuffer('epochEventType','stimulus.target','freqband',[.1 .3 20 25],'clsfr_type','erp','trlen_ms',trlen_ms); | %matexe% %matopts%
)