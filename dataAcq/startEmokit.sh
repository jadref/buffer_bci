#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir=`dirname $0`
if [ `uname -s` == 'Linux' ]; then
   if [ -r $buffdir/buffer/bin/glnx86/emokit2ft ]; then
	 buffexe=$buffdir'/buffer/bin/glnx86/emokit2ft';
   fi
   if [ -r $buffdir/buffer/glnx86/emokit2ft ]; then
	 buffexe=$buffdir'/buffer/glnx86/emokit2ft';
   fi
else # Mac
   if [ -r $buffdir/buffer/bin/maci/emokit2ft ]; then
	 buffexe=$buffdir'/buffer/bin/maci/emokit2ft';
   fi
   if [ -r $buffdir/buffer/maci/emokit2ft ]; then
	 buffexe=$buffdir'/buffer/maci/emokit2ft';
   fi
fi
$buffexe "$@"
