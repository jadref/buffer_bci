#!/bin/bash
cd `pwd`
java -cp build/jar/Mobita2ft.jar:../../dataAcq/buffer/java/BufferClient.jar nl.dcc.buffer_bci.Mobita2ft $@
