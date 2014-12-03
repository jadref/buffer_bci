set javaexe="" 
FOR /d %%f in ("C:\Program Files\Java\jre*" "C:\Program Files (x86)\Java\jre*") DO (
	 if exist "%%f\bin\java.exe" ( 
	 set javadir=%%f
	 set javaexe="%%f\bin\java.exe"
rem	 exit /b 
	 )
)


