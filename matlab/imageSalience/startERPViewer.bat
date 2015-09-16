call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "../utilities/initPaths.m;erpViewer([],[],'trlen_ms',1000,'cuePrefix','stimulus.target','endType',{'startPhase.cmd' 'exit'});quit;" %matopts%
) else (
  echo run ../utilities/initPaths.m;erpViewer([],[],'trlen_ms',1000,'cuePrefix','stimulus.target','endType',{{'startPhase.cmd'} {'exit'}});quit; | %matexe% %matopts%
)
