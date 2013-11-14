call ..\utilities\findMatlab.bat
start "Matlab" %matexe% -nodesktop -r "run ../utilities/initPaths;erpViewer();quit;"
