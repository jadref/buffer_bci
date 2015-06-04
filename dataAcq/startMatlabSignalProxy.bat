call ..\utilities\findMatlab.bat
set batdir=%~dp0
cd %batdir%
echo run ../utilities/initPaths.m;buffer_signalproxy('localhost',1972,'stimEventRate',0,'queueEventRate',0);quit; | %matexe%