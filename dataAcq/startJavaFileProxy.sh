#!/bin/bash
buffdir=`dirname ${BASH_SOURCE[0]}`
echo Starting: ${buffdir}/buffer/java/FilePlayback.jar $@
java -cp ${buffdir}/buffer/java/BufferClient.jar:${buffdir}/buffer/java/FilePlayback.jar nl.dcc.buffer_bci.FilePlayback $@
