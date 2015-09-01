call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "sigViewer();quit()"  
) else (
  echo  sigViewer | %matexe% %matopts%
)