call ..\utilities\findMatlab.bat
set batdir=%~dp0
cd %batdir%
start "Matlab" %matexe% -nodesktop -r "run ../utilities/initPaths;buffer_signalproxy('localhost',1972,'stimEventRate',0,'queueEventRate',0);quit;"