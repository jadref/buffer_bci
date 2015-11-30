call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "configureIM;startSigProcBuffer('epochEventType','stimulus.target','freqband',[6 8 28 30],'clsfr_type','ersp','trlen_ms',trlen_ms,'trainOpts',trainOpts,'contFeedbackOpts',contFeedbackOpts,'epochFeedbackOpts',epochFeedbackOpts,'useGUI',0);quit;" %matopts%
) else (
echo configureIM;startSigProcBuffer^('epochEventType','stimulus.target','freqband',[6 8 28 30],'clsfr_type','ersp','trlen_ms',trlen_ms,'trainOpts',trainOpts,'contFeedbackOpts',contFeedbackOpts,'epochFeedbackOpts',epochFeedbackOpts,'useGUI',0^);quit; | %matexe% %matopts%
)
