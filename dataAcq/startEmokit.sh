#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir=`dirname $0`
execname=emokit2ft
if [ `uname -s` == 'Linux' ]; then
	 if  [ "`uname -a`" == 'armv6l' ]; then
		  arch='raspberrypi'
    else
		  arch='glnx86';
   fi	 
else # Mac
	 arch='maci';
fi
if [ -r "$buffdir/buffer/bin/${arch}/${execname}" ]; then
	 buffexe="$buffdir/buffer/bin/${arch}/${execname}";
fi
if [ -r "$buffdir/buffer/${arch}/${execname}" ]; then
	 buffexe="$buffdir/buffer/${arch}/${execname}";
fi
$buffexe "$@"
