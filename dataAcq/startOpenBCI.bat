call ..\utilities\findJava.bat
rem TODO : auto search for the serial device?
set usbPort=COM1
%javaexe% -cp "buffer/java/BufferClient.jar;openBCI/lib/jssc.jar;openBCI/openBCI2ft.jar" openBCI2ft %usbPort%
