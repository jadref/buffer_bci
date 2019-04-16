set batdir=%~dp0
cd %batdir%
call ..\utilities\findJava.bat
rem TODO : auto search for the serial device?
set usbPort=COM4
set buffserver=localhost:1972
set nCh=8
set useAux=0
set serialEvent=1
set bufPktSize=-1
%javaexe% -cp "buffer/java/BufferClient.jar;buffer/java/jssc.jar;buffer/java/openBCI2ft.jar" openBCI2ft %usbPort% %buffserver% %nCh% %useAux% %serialEvent% %bufPktSize% %*
if errorlevel 1 (
	msg /w * "If you cannot connect to the openBCI because the dongle doesnt connect.  Then you can try installing the dongle driver,from: <buffer/win32/CDM v2.12.00 WHQL Certified.exe>? or download from : <http://www.ftdichip.com/Drivers/VCP.htm> && pause"
)

