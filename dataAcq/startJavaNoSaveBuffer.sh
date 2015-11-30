#!/bin/bash
buffdir=`dirname $0`

if [ $# -lt 1 ]; then 
  port=1972;
else
  port=$1;
  shift;
fi

echo Starting: ${buffdir}/buffer/java/BufferServer.jar $port $@
exec java -jar ${buffdir}/buffer/java/BufferServer.jar $port $@
