set batdir=%~dp0
cd %batdir%
call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "artifactCalibrationStimulus;quit;" %matopts%
) else (
  echo artifactCalibrationStimulus; | %matexe% %matopts%
)
