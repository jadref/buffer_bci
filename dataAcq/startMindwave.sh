#! /usr/bin/env bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir=`dirname $0`
if [ `uname -s` == 'Linux' ]; then
   if [ -r $buffdir/buffer/bin/glnx86/thinkgear2ft ]; then
	 buffexe=$buffdir'/buffer/bin/glnx86/thinkgear2ft';
   fi
   if [ -r $buffdir/buffer/glnx86/thinkgear2ft ]; then
	 buffexe=$buffdir'/buffer/glnx86/thinkgear2ft';
   fi
	# find the BT device!
else # Mac
   if [ -r $buffdir/buffer/bin/maci/thinkgear2ft ]; then
	 buffexe=$buffdir'/buffer/bin/maci/thinkgear2ft';
   fi
   if [ -r $buffdir/buffer/maci/thinkgear2ft ]; then
	 buffexe=$buffdir'/buffer/maci/thinkgear2ft';
   fi
fi
$buffexe /dev/bt0 mindwave.cfg localhost:1972
