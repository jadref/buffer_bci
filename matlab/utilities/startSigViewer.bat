call ..\..\utilities\findMatlab.bat
cd %~dp0
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "sigViewer();quit()"  
) else (
  echo  sigViewer;quit | %matexe% %matopts%
)
