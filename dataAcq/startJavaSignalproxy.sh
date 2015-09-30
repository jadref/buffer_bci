#!/bin/bash
buffdir=`dirname ${BASH_SOURCE[0]}`
echo Starting: ${buffdir}/buffer/java/SignalProxy.jar $@
java -cp ${buffdir}/buffer/java/BufferClient.jar:${buffdir}/buffer/java/SignalProxy.jar nl.dcc.buffer_bci.SignalProxy $@
