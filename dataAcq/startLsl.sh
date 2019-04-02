#! /usr/bin/env bash
cd `dirname "${BASH_SOURCE[0]}"`
cat<<EOF
Usage:  startLsl  LSLName buffhost buffport
EOF
java -cp buffer/java/BufferClient.jar:buffer/java/lsl2ft.jar:buffer/java/jna-4.0.0.jar:buffer/java Lsl2ft $*
