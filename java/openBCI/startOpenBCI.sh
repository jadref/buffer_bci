#!/usr/bin/env bash
# TODO : auto search for the serial device?
usbPort=/dev/ttyUSB0
if [ $# -gt 0 ]; then
	 usbPort=$1
	 shift
fi
java -cp lib/BufferClient.jar:lib/jssc.jar:openBCI2ft.jar openBCI2ft $usbPort $@
