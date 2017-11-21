set matexe="" 
set ismatlab=1
set matopts=""
FOR /d %%f in ("C:\Program Files\MATLAB\*" "C:\Program Files (x86)\MATLAB\*" "D:\Program Files\MATLAB\*") DO (
	 if exist "%%f\bin\matlab.exe" ( 
	 set matexe="%%f\bin\matlab.exe"
     set matopts="-nodesktop"
	 set ismatlab=1
rem	 exit /b 
	 )
)

FOR /d %%f in ("C:\Program Files\Octave\*" "C:\Program Files (x86)\Octave\*" "C:\Octave\*") DO (
	 if exist "%%f\bin\octave.exe" ( 
	 set matexe="%%f\bin\octave.exe"
	 set ismatlab=0
	 set matopts="--line-editing"
rem	 exit /b 
	)
	if exist "%%f\bin\octave-cli.exe" ( 
	 set matexe="%%f\bin\octave-cli.exe"
	 set ismatlab=0
	 set matopts="--line-editing"
rem	 exit /b 
	 )
	if exist "%%f\bin\octave-gui.exe" ( 
	 set matexe="%%f\bin\octave-gui.exe"
	 set ismatlab=0
	 set matopts="--no-gui"
rem	 exit /b 
	 )
)


