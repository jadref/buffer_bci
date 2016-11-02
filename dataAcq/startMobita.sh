#! /usr/bin/env bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir=`dirname $0`
execname='mobita2ft'
if [ `uname -s` == 'Linux' ]; then
	 if  [ "`uname -a`" == 'armv6l' ]; then
		  arch='raspberrypi'
    else
		  arch='glnx86';
   fi
   sudo killall -STOP NetworkManager
else # Mac
	 arch='maci'
fi
buffexe="$buffdir/buffer/bin/${execname}";
if [ -r "$buffdir/${execname}" ]; then
    buffexe="$buffdir/${execname}";
fi
if [ -r "$buffdir/buffer/bin/${arch}/${execname}" ]; then
	 buffexe="$buffdir/buffer/bin/${arch}/${execname}";
fi
if [ -r "$buffdir/buffer/${arch}/${execname}" ]; then
	 buffexe="$buffdir/buffer/${arch}/${execname}";
fi

if [ $# -lt 1 ]; then
  bufferhost=localhost:1972;
else
  bufferhost=$1;
  shift;
fi

if [ `uname -s` == 'Linux' ]; then
  trap 'killall -CONT NetworkManager' SIGTERM SIGINT SIGHUP
fi

$buffexe 10.11.12.13:4242 $bufferhost 50 4 "$@"

if [ `uname -s` == 'Linux' ]; then
   sudo killall -CONT NetworkManager
fi
