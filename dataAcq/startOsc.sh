#! /usr/bin/env bash
cd `dirname "${BASH_SOURCE[0]}"`
cat<<EOF
Usage:  startOsc OSCPath buffhost:buffport nChan fSample
EOF
java -cp buffer/java/BufferClient.jar:buffer/java/JavaOSC.jar:buffer/java osc2ft $*
