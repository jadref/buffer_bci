#!/bin/bash
buffdir=`dirname ${BASH_SOURCE[0]}`
buffinfo=localhost:1972
if [ $# -gt 0 ]; then
	 buffinfo=$1;
	 shift;
fi
echo Starting: ${buffdir}/buffer/java/AudioToBuffer.jar $@
exec java -cp ${buffdir}/buffer/java/BufferClient.jar:${buffdir}/buffer/java/AudioToBuffer.jar nl.dcc.buffer_bci.AudioToBuffer $buffinfo 441 $@
