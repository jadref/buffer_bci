#!/bin/bash
buffdir=`dirname $0`
echo Starting: ${buffdir}/buffer/java/EventViewer.class $@
java -cp ${buffdir}/buffer/java/BufferClient.jar:${buffdir}/buffer/java EventViewer $@
