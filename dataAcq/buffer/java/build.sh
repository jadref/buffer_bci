#!/bin/bash
cd `dirname $0`
javac -target 1.4 -source 1.4 nl/fcdonders/fieldtrip/*.java
jar cf Buffer.jar nl
