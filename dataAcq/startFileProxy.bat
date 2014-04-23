call ..\utilities\findMatlab.bat
set batdir=%~dp0
cd %batdir%
start "Matlab" %matexe% -nodesktop -r "run ../utilities/initPaths;buffer_fileproxy([],[],'%1');quit;"
