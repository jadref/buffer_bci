#!/bin/bash
cd `dirname $0`
# build the buffer client
echo Building imagined movement experiment
javac -target 1.5 -source 1.5 -classpath ../../dataAcq/buffer/java/BufferClient.jar:commons-configuration-1.10/commons-configuration-1.10.jar:commons-lang-2.6/commons-lang-2.6.jar nl/dcc/buffer_bci/imaginedMovement/*.java nl/dcc/buffer_bci/imaginedMovement/buffer/*.java nl/dcc/buffer_bci/imaginedMovement/views/*.java
echo Making imaginedMovement.jar
jar cfm imaginedMovement.jar MANIFEST.MF nl/dcc/buffer_bci/imaginedMovement resources/*
