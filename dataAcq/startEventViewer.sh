#!/bin/bash
buffdir=`dirname $0`
if [ `uname -s` == 'Linux' ]; then
   buffexe=$buffdir'/buffer/bin/';
   if [ -r $buffdir/eventViewer ]; then
    buffexe=$buffdir'/eventViewer';
   fi
   if [ -r $buffdir/buffer/bin/glnx86/eventViewer ]; then
	 buffexe=$buffdir'/buffer/bin/glnx86/eventViewer';
   fi
   if [ -r $buffdir/buffer/glnx86/eventViewer ]; then
	 buffexe=$buffdir'/buffer/glnx86/eventViewer';
   fi
else # Mac
   buffexe=$buffdir'/buffer/bin/eventViewer';
   if [ -r $buffdir/buffer/bin/maci/eventViewer ]; then
	 buffexe=$buffdir'/buffer/bin/maci/eventViewer'
   fi
   if [ -r $buffdir/buffer/maci/eventViewer ]; then
	 buffexe=$buffdir'/buffer/maci/eventViewer'
   fi
fi
$buffexe 
