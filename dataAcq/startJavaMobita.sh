#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir=`dirname $0`
java -cp ${buffdir}/buffer/java/Mobita2ft.jar:${buffdir}/buffer/java/BufferClient.jar Mobita2ft.Mobita2ft $@
