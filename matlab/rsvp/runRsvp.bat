call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "runRsvp;quit;" %matopts%
) else (
  echo runRsvp | %matexe% %matopts%
)