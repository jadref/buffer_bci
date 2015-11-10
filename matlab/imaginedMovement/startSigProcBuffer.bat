call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "configureIM;startSigProcBuffer('epochEventType','stimulus.target','freqband',[6 8 28 30],'clsfr_type','ersp','trlen_ms',trlen_ms,'contFeedbackOpts',contFeedbackOpts,'epochFeedbackOpts',epochFeedbackOpts);quit;" %matopts%
) else (
echo configureIM;startSigProcBuffer^('epochEventType','stimulus.target','freqband',[6 8 28 30],'clsfr_type','ersp','trlen_ms',trlen_ms,'contFeedbackOpts',contFeedbackOpts,'epochFeedbackOpts',epochFeedbackOpts^);quit; | %matexe% %matopts%
)
