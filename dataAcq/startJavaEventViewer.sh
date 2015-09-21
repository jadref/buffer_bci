#!/bin/bash
buffdir=`dirname $0`
echo Starting: ${buffdir}/buffer/java/eventViewer.class $@
java -cp ${buffdir}/buffer/java/BufferClient.jar:${buffdir}/buffer/java eventViewer $@
