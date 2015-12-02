set batdir=%~dp0
cd %batdir%
call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "run ../utilities/initPaths.m;buffer_signalproxy('localhost',1972,'stimEventRate',0,'queueEventRate',0);quit;" %matopts%
) else (
echo run ../utilities/initPaths.m;buffer_signalproxy^('localhost',1972,'stimEventRate',0,'queueEventRate',0^);quit | %matexe% %matopts%
)
