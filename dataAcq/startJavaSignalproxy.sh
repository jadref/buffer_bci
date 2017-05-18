#!/bin/bash
buffdir=`dirname ${BASH_SOURCE[0]}`
buffinfo=localhost:1972
if [ $# -gt 0 ]; then
	 buffinfo=$1;
	 shift;
fi
cat<<EOF
Usage: startJavaSignalProxy.sh buffhost:buffport fsample nchans blockSize
where:
	 buffersocket	 is a string of the form bufferhost:bufferport (localhost:1972)
	 fsample	 is the frequency data is generated in Hz                 (100)
	 nchans	 is the number of simulated channels to make                 (3)
	 blocksize	 is the number of samples to send in one packet           (5)
EOF
echo Starting: ${buffdir}/buffer/java/SignalProxy.jar $@
exec java -cp ${buffdir}/buffer/java/BufferClient.jar:${buffdir}/buffer/java/SignalProxy.jar nl.dcc.buffer_bci.SignalProxy $buffinfo $@
