#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
echo Starting: ${buffdir}/buffer/java/filePlayback.class $outdir $@
java -cp buffer/java/BufferClient.jar:buffer/java filePlayback $@
