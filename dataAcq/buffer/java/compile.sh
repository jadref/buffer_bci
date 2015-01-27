#!/bin/bash
cd `dirname $0`
# build the buffer client
echo Building bufferclient
javac -target 1.4 -source 1.4 nl/fcdonders/fieldtrip/bufferclient/*.java
echo Making bufferclient.jar
jar cf BufferClient.jar nl/fcdonders/fieldtrip/bufferclient

# build the buffer server
echo Building bufferserver
javac -target 1.5 -source 1.5 nl/fcdonders/fieldtrip/bufferserver/*.java
javac -target 1.5 -source 1.5 nl/fcdonders/fieldtrip/bufferserver/data/*.java
javac -target 1.5 -source 1.5 nl/fcdonders/fieldtrip/bufferserver/exceptions/*.java
javac -target 1.5 -source 1.5 nl/fcdonders/fieldtrip/bufferserver/network/*.java
echo Making bufferserver jar
jar cfe BufferServer.jar nl.fcdonders.fieldtrip.bufferserver.BufferServer nl/fcdonders/fieldtrip/bufferserver