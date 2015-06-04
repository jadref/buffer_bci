#!/bin/bash
buffdir=`dirname $0`
echo Starting: ${buffdir}/buffer/java/BufferServer.jar
java -jar ${buffdir}/buffer/java/BufferServer.jar $@
