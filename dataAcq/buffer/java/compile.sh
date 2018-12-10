#!/bin/bash
cd `dirname $0`
# build the buffer client
echo Building bufferclient
javac --release 7 nl/fcdonders/fieldtrip/bufferclient/*.java
echo Making bufferclient.jar
jar cf BufferClient.jar nl/fcdonders/fieldtrip/bufferclient

# build the buffer server
echo Building bufferserver
javac --release 7 nl/fcdonders/fieldtrip/bufferserver/*.java
javac --release 7 nl/fcdonders/fieldtrip/bufferserver/data/*.java
javac --release 7 nl/fcdonders/fieldtrip/bufferserver/exceptions/*.java
javac --release 7 nl/fcdonders/fieldtrip/bufferserver/network/*.java
echo Making bufferserver jar
jar cfe BufferServer.jar nl.fcdonders.fieldtrip.bufferserver.BufferServer nl/fcdonders/fieldtrip/bufferserver
