set javadir=""
set javaexe="java" 
FOR /d %%f in ("C:\Program Files\Java\jre*" "C:\Program Files (x86)\Java\jre*" "C:\Program Files\Java\jdk*" "C:\Program Files (x86)\Java\jdk*") DO (
	 if exist "%%f\bin\java.exe" ( 
	 set javadir=%%f
	 set javaexe="%%f\bin\java.exe"
rem	 exit /b 
	 )
)


