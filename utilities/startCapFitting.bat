call ..\utilities\findMatlab.bat
start "Matlab" %matexe% -nodesktop -nosplash -r "run ../utilities/initPaths;capFitting('capFile','cap_tmsi_mobita_black','overridechnms',1);quit;"
