set matexe="" 
FOR /d %%f in ("C:\Program Files\MATLAB\*" "C:\Program Files (x86)\MATLAB\*") DO (
	 if exist "%%f\bin\matlab.exe" ( set matexe="%%f\bin\matlab.exe" )
)



