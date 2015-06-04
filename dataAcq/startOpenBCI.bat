call ..\utilities\findJava.bat
rem TODO : auto search for the serial device?
set usbPort=COM1
%javaexe% -cp "buffer/java/BufferClient.jar;openBCI/lib/jssc.jar;openBCI/openBCI2ft.jar" openBCI2ft %usbPort%
if errorlevel 1 (
	start cmd /c "echo If you cannot connect to the openBCI because the dongle doesnt connect.  Then you can try installing the dongle driver,from:\n buffer/win32/CDM\ v2.12.00\ WHQL\ Certified.exe? or download from : <http://www.ftdichip.com/Drivers/VCP.htm> && pause"
)

