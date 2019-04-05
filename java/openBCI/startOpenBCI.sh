#!/usr/bin/env bash
# TODO : auto search for the serial device?
usbPort=/dev/ttyUSB0
if [ $# -gt 0 ]; then
	 usbPort=$1
	 shift
fi
# ensure the port is in low-latency mode to avoid annoying data delays
echo 1 >  /sys/bus/usb-serial/devices/$usbPort/latency_timer
setserial $usbPort low_latency
# start the driver
java -cp lib/BufferClient.jar:lib/jssc.jar:openBCI2ft.jar openBCI2ft $usbPort $@
