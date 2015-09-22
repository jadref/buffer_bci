call ..\utilities\findMatlab.bat
set batdir=%~dp0
cd %batdir%
echo run ../utilities/initPaths.m;buffer_fileproxy^([],[],'%1'^);quit; | %matexe% %matopts%
