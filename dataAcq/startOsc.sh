#! /usr/bin/env bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir=`dirname $0`
cat<<EOF
Usage:  startOsc OSCPath buffhost:buffport nChan fSample
EOF
java -cp ${buffdir}/buffer/java/BufferClient.jar:${buffdir}/buffer/java/JavaOSC.jar:${buffdir}/buffer/java osc2ft $*
