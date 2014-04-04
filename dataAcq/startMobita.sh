#! /usr/bin/env bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir=`dirname $0`
if [ `uname -s` == 'Linux' ]; then
   if [ -r $buffdir/buffer/bin/glnx86/mobita2ft ]; then
	 buffexe=$buffdir'/buffer/bin/glnx86/mobita2ft';
   fi
   if [ -r $buffdir/buffer/glnx86/mobita2ft ]; then
	 buffexe=$buffdir'/buffer/glnx86/mobita2ft';
   fi
   sudo killall -STOP NetworkManager
else # Mac
   if [ -r $buffdir/buffer/bin/maci/mobita2ft ]; then
	 buffexe=$buffdir'/buffer/bin/maci/mobita2ft';
   fi
   if [ -r $buffdir/buffer/maci/mobita2ft ]; then
	 buffexe=$buffdir'/buffer/maci/mobita2ft';
   fi
fi
$buffexe 10.11.12.13:4242 localhost:1972 50 4 "$@"

if [ `uname -s` == 'Linux' ]; then
   sudo killall -CONT NetworkManager
fi
