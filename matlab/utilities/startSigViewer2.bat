call ..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "sigViewer([],1973);quit;" %matopts%
) else (
  echo sigViewer^([],1973^);quit; | %matexe% %matopts%
)
