call ..\utilities\findMatlab.bat
set batdir=%~dp0
cd %batdir%
echo run ../utilities/initPaths.m;eventViewer();quit; | %matexe%
