call ..\utilities\findMatlab.bat
start "Matlab" %matexe% -nodesktop -nosplash -r "sigViewer([],1973);quit;"
