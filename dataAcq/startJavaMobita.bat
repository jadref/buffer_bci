set batdir=%~dp0
cd %batdir%
call "%batdir%\..\utilities\findJava.bat"
%javaexe% -cp "buffer/java/Mobita2ft.jar;buffer/java/BufferClient.jar" Mobita2ft.Mobita2ft %*
if errorlevel 1 (
	start cmd /c "echo If you cannot connect to the openBCI because the dongle doesnt connect.  Then you can try installing the dongle driver,from:\n buffer/win32/CDM\ v2.12.00\ WHQL\ Certified.exe? or download from : <http://www.ftdichip.com/Drivers/VCP.htm> && pause"
)

