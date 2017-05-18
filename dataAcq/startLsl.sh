#! /usr/bin/env bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir=`dirname $0`
cat<<EOF
Usage:  startLsl  LSLName buffhost buffport
EOF
java -cp ${buffdir}/buffer/java/BufferClient.jar:${buffdir}/buffer/java/lsl2ft.jar:${buffdir}/buffer/java/jna-4.0.0.jar:${buffdir}/buffer/java Lsl2ft $*
