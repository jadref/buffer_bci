#!/bin/bash
buffdir=`dirname "${BASH_SOURCE[0]}"`
buffinfo=localhost:1972
if [ $# -gt 0 ]; then
	 buffinfo=$1;
	 shift;
fi
exec java -cp ../../dataAcq/buffer/java/BufferClient.jar:build/jar/SignalProxy.jar nl.dcc.buffer_bci.SignalProxy $buffinfo $@
