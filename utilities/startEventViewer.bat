call ..\utilities\findMatlab.bat
set batdir=%~dp0
cd %batdir%
start "Matlab" %matexe% -nodesktop -nosplash -r "run ../utilities/initPaths;eventViewer();quit;"
