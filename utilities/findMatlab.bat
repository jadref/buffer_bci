set matexe="" 
rem search for octave first
FOR /d %%f in ("C:\Program Files\Octave\*" "C:\Program Files (x86)\Octave\*" "C:\Octave\*") DO (
	 if exist "%%f\bin\octave.exe" ( 
	 set matexe="%%f\bin\octave.exe"
rem	 exit /b 
	 )
)

rem search matlab later, if found this is prefered
FOR /d %%f in ("C:\Program Files\MATLAB\*" "C:\Program Files (x86)\MATLAB\*") DO (
	 if exist "%%f\bin\matlab.exe" ( 
	 set matexe="%%f\bin\matlab.exe"
rem	 exit /b 
	 )
)

