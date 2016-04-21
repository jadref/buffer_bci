set pythonexe="" 
FOR /d %%f in ("C:\Python*" "C:\Program Files (x86)\Python*" "C:\Anaconda2") DO (
	 if exist "%%f\python.exe" ( 
	 set pythondir=%%f
	 set pythonexe="%%f\python.exe"
rem	 exit /b 
	 )
)


