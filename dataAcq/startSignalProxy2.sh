#!/bin/bash
buffdir=`dirname $0`
if [ `uname -s` == 'Linux' ]; then
   buffexe=$buffdir'/buffer/bin/';
   if [ -r $buffdir/csignalproxy ]; then
    buffexe=$buffdir'/csignalproxy';
   fi
   if [ -r $buffdir/buffer/bin/glnx86/csignalproxy ]; then
	 buffexe=$buffdir'/buffer/bin/glnx86/csignalproxy';
   fi
   if [ -r $buffdir/buffer/glnx86/csignalproxy ]; then
	 buffexe=$buffdir'/buffer/glnx86/csignalproxy';
   fi
else # Mac
   buffexe=$buffdir'/buffer/bin/csignalproxy';
   if [ -r $buffdir/buffer/bin/maci/csignalproxy ]; then
	 buffexe=$buffdir'/buffer/bin/maci/csignalproxy'
   fi
   if [ -r $buffdir/buffer/maci/csignalproxy ]; then
	 buffexe=$buffdir'/buffer/maci/csignalproxy'
   fi
fi
$buffexe $@
