set matexe="" 
FOR /d %%f in ("C:\Program Files (x86)\MATLAB\*" "C:\Program Files\MATLAB\*" ) DO (
	 rem if exist "%%f\bin\matlab.exe" ( 
	 rem set matexe="%%f\bin\matlab.exe"
	 rem exit /b 
	 rem )
)



