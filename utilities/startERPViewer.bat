call ..\utilities\findMatlab.bat
set batdir=%~dp0
cd %batdir%
start "Matlab" %matexe% -nodesktop -nojvm -r "run ../utilities/initPaths;erpViewer();quit;"
