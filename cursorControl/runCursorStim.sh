#!/bin/bash
batdir=`dirname $0`

java -cp "${batdir}/lib/BufferClient.jar:${batdir}/build/jar/CursorStim.jar" nl.ru.dcc.buffer_bci.CursorStim $@
