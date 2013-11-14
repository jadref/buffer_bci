call ..\utilities\findMatlab.bat
start "matlab" %matexe% -nodesktop -nosplash -minimize -singleCompThread -r "capFile='cap_tmsi_mobita_p300';startSigProcBuffer;quit;"