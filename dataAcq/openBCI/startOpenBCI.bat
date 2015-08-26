rem TODO : auto search for the serial device?
set usbPort=COM8
java -cp "lib/BufferClient.jar;lib/jssc.jar;openBCI2ft.jar" openBCI2ft %usbPort% localhost:1972 1 0 1
if errorlevel 1 (
	start cmd /c "echo If you cannot connect to the openBCI because the dongle doesnt connect.  Then you can try installing the dongle driver,from:\n buffer/win32/CDM\ v2.12.00\ WHQL\ Certified.exe? or download from : <http://www.ftdichip.com/Drivers/VCP.htm> && pause"
)

