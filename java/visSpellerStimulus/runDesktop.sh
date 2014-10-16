#/bin/bash
curdir=`dirname $0`
jarfile=${curdir}/desktop/build/libs/desktop-*.jar
echo Starting: $jarfile
java -jar $jarfile
