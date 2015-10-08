call ..\utilities\findMatlab.bat
set batdir=%~dp0
cd %batdir%
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "run ../matlab/utilities/initPaths.m;buffer_signalproxy('localhost',1972,'stimEventRate',0,'queueEventRate',0);quit;" %matopts%
) else (
echo run ../matlab/utilities/initPaths.m;buffer_signalproxy^('localhost',1972,'stimEventRate',0,'queueEventRate',0^);quit | %matexe% %matopts%
)
