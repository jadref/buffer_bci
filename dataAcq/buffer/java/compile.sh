#!/bin/bash
cd `dirname "$0"`

# force to use older java compilier
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64
# build the buffer client
echo Building bufferclient
${JAVA_HOME}/bin/javac -source 1.8 -target 1.8 nl/fcdonders/fieldtrip/bufferclient/*.java
echo Making bufferclient.jar
jar cf BufferClient.jar nl/fcdonders/fieldtrip/bufferclient

# build the buffer server
echo Building bufferserver
${JAVA_HOME}/bin/javac -source 1.8 -target 1.8 nl/fcdonders/fieldtrip/bufferserver/*.java
${JAVA_HOME}/bin/javac -source 1.8 -target 1.8 nl/fcdonders/fieldtrip/bufferserver/data/*.java
${JAVA_HOME}/bin/javac -source 1.8 -target 1.8 nl/fcdonders/fieldtrip/bufferserver/exceptions/*.java
${JAVA_HOME}/bin/javac -source 1.8 -target 1.8 nl/fcdonders/fieldtrip/bufferserver/network/*.java
echo Making bufferserver jar
jar cfe BufferServer.jar nl.fcdonders.fieldtrip.bufferserver.BufferServer nl/fcdonders/fieldtrip/bufferserver
