#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
echo Starting: ${buffdir}/buffer/java/filePlayback.class $outdir $@
java -cp ${buffdir}/buffer/java/BufferClient.jar:${buffdir}/buffer/java filePlayback $@
