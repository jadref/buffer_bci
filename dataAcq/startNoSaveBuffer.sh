#!/bin/bash
buffdir=`dirname $0`
# Identify the OS and search for the appropriate executable
if [ `uname -s` == 'Linux' ]; then
	 if  [ "`uname -a`" == 'armv6l' ]; then
		  arch='raspberrypi'
    else
		  arch='glnx86';
   fi
elif [[ `uname -s` = 'MINGW'* ]]; then
	 arch='win32'
	 buffexe=$bufdir'/buffer/win32/demo_buffer_unix'
else # Mac
	arch='maci';
fi
# Search for the exec in the standard places
if [ -r $buffdir/buffer/bin/${arch}/buffer ]; then
	 buffexe=$buffdir"/buffer/bin/${arch}/buffer";
fi
if [ -r $buffdir/buffer/${arch}/buffer ]; then
	 buffexe=$buffdir"/buffer/${arch}/buffer";
fi

echo Starting: $buffexe
# turn return into carriage return to stop endless scrolling of the window
if [ -z `which tr` ]; then
  $buffexe $@
else
  $buffexe $@ | tr '\n' '\r'
fi
