call ..\utilities\findMatlab.bat
rem Argh matlab doesn't support stdin, octave doesn't support -r.....
if "%ismatlab%" == 1 (
  start "Matlab" /b %matexe% -r "sigViewer();quit()"
) else (
  echo sigViewer();quit; | %matexe%
)