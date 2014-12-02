#! /usr/bin/env bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir=`dirname $0`

oscport=1234
#oscdevice=ffc3
# 1) run the OSC -> ft_buffer converter with parameters for the MUSE  !in the background!
#    This will then wait for data from the MUSE and connection to the buffer
java -cp buffer/java/Buffer.jar:osc/JavaOSC.jar:osc osc2ft /muse/eeg/raw:${oscport} localhost:1972 6 220 1 10 &
# catch ctrl-c and kill the java too
trap 'kill %1' SIGTERM SIGINT SIGHUP

if [ `uname -s` == 'Linux' ]; then
	 echo Sorry Linux isnt supported yet!
	 kill %1 # kill the background java job
	 exit -1	 
else
   if [ -r $buffdir/buffer/bin/maci/muse-io ]; then
    # Argh, annoyingly the MUSE driver only works if run in it's own directory
    cd $buffdir'/buffer/bin/maci';
   fi
   if [ -r $buffdir/buffer/maci/mobita2ft ]; then
	 cd $buffdir'/buffer/maci';
   fi	 
	buffexe='./muse-io';
   export DYLD_LIBRARY_PATH=`pwd`:$DYLD_LIBRARY_PATH
fi
# 2) run the muse-io driver, by default search for device with name muse
$buffexe --preset ab --osc osc.udp://localhost:$oscport
if [ $? -ne 0 ]; then
	 echo "Error couldn't connect to the MUSE"
	 kill %1 # kill the background java job
	 exit -1
fi
