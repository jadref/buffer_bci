call ..\utilities\findMatlab.bat
echo startSigProcBuffer('epochEventType','stimulus.target','freqband',[.1 1 10 12],'clsfr_type','erp','trlen_ms',700);quit; | %matexe% %matopts%
