call ..\utilities\findMatlab.bat
start "Matlab" %matexe% -nodesktop -nosplash -r "run ../utilities/initPaths;erpViewer();quit;"