call ..\..\utilities\findMatlab.bat
echo startSigProcBuffer('epochEventType','stimulus.target','testepochEventType','stimulus.image','freqband',[.1 1 10 12],'clsfr_type','erp','trlen_ms',1300);quit; | %matexe% %matopts%
