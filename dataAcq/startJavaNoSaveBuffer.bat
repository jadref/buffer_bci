#!/bin/bash
buffdir=`dirname $0`
call ../utilites/findJava.bat
if [ $# -lt 1 ]; then 
  port=1972;
else
  port=$1;
  shift;
fi
echo Starting: %javaexe% ${buffdir}/buffer/java/BufferServer.jar
%javaexe% -jar ${buffdir}/buffer/java/BufferServer.jar $port $@
