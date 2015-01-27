#!/bin/bash
buffdir=`dirname $0`
echo Starting: ${buffdir}/buffer/java/eventViewer.class $outdir $@
java -cp buffer/java/BufferClient.jar:buffer/java eventViewer $@
