call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "runImageSalience;quit;" %matopts%
) else (
  echo runImageSalience | %matexe% %matopts%
)