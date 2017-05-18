#! /usr/bin/env bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir=`dirname $0`
#    This will then wait for data from the MUSE and connection to the buffer
if [ $# -lt 1 ]; then 
  bufferhost=localhost:1972;
else
  bufferhost=$1;
  shift;
fi
java -cp ${buffdir}/buffer/java/BufferClient.jar:${buffdir}/buffer/java/lsl2ft.jar:${buffdir}/buffer/java/jna-4.0.0.jar:${buffdir}/buffer/java Lsl2ft $*
