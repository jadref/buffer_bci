set batdir=%~dp0
cd %batdir%
call ..\utilities\findJava.bat

echo Usage: startJavaSignalProxy.sh buffhost:buffport fsample nchans blockSize
echo where:
echo 	 buffersocket	 is a string of the form bufferhost:bufferport (localhost:1972)
echo 	 fsample	 is the frequency data is generated in Hz                 (100)
echo 	 nchans	 is the number of simulated channels to make                 (3)
echo 	 blocksize	 is the number of samples to send in one packet           (5)
echo 
echo Starting: /buffer/java/SignalProxy.jar
%javaexe% -cp "buffer\java\BufferClient.jar;buffer\java\SignalProxy.jar" nl.dcc.buffer_bci.SignalProxy localhost:1972 %*
