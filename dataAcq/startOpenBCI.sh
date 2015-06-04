#!/usr/bin/env bash
# TODO : auto search for the serial device?
usbPort=/dev/ttyUSB0
if [ $# -gt 0 ]; then
	 usbPort=$1
	 shift
fi
java -cp buffer/java/BufferClient.jar:openBCI/lib/jssc.jar:openBCI/openBCI2ft.jar openBCI2ft $usbPort $@
