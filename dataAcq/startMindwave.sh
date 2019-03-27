#! /usr/bin/env bash
cd `dirname "${BASH_SOURCE[0]}"`
execname='thinkgear2ft'
if [ `uname -s` == 'Linux' ]; then
	 if  [ "`uname -a`" == 'armv6l' ]; then
		  arch='raspberrypi'
    else
		  arch='glnx86';
   fi
else # Mac
	 arch='maci'
fi
buffexe="buffer/bin/${execname}";
if [ -r ${execname} ]; then
    buffexe="${execname}";
fi
if [ -r buffer/bin/${arch}/${execname} ]; then
	 buffexe="buffer/bin/${arch}/${execname}";
fi
if [ -r buffer/${arch}/${execname} ]; then
	 buffexe="buffer/${arch}/${execname}";
fi
$buffexe /dev/ttyUSB0 mindwave.cfg localhost 1972
