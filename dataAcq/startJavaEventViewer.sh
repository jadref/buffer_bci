#!/bin/bash
buffdir=`dirname $0`
echo Starting: ${buffdir}/buffer/java/eventViewer.class $@
java -cp buffer/java/BufferClient.jar:buffer/java eventViewer $@
