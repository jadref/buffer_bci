call ..\utilities\findMatlab.bat
start "matlab" %matexe% -nodesktop -nosplash -minimize -singleCompThread -r "configureIM;startSigProcBuffer('epochEventType','stimulus.target','freqband',[6 8 28 30],'clsfr_type','ersp','trlen_ms',trlen_ms,'contPredFilt',contPredFilt,'epochPredFilt',epochPredFilt);quit;"
