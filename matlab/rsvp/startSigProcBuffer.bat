call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "run ../../utilities/initPaths.m;startSigProcBuffer('epochEventType','stimulus.tgtState','testepochEventType','stimulus.stimState','freqband',[.1 1 10 12],'clsfr_type','erp','trlen_ms',700,'erpOpts',{'closeFig',0});quit();" %matopts%
) else (
  echo run ../../utilities/initPaths.m;startSigProcBuffer^('epochEventType','stimulus.tgtState','testepochEventType','stimulus.stimState','freqband',[.1 1 10 12],'clsfr_type','erp','trlen_ms',700,'erpOpts',{'closeFig',0}^);quit | %matexe% %matopts%
)
