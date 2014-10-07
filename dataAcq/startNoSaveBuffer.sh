#!/bin/bash
buffdir=`dirname $0`
if [ `uname -s` == 'Linux' ]; then
   buffexe=$buffdir'/buffer/bin/demo_buffer';
   if [ -r $buffdir/demo_buffer ]; then
    buffexe=$buffdir'/demo_buffer';
   fi
   if [ -r $buffdir/buffer/bin/glnx86/demo_buffer ]; then
	 buffexe=$buffdir'/buffer/bin/glnx86/demo_buffer';
   fi
   if [ -r $buffdir/buffer/glnx86/demo_buffer ]; then
	 buffexe=$buffdir'/buffer/glnx86/demo_buffer';
   fi
   if [ -r $buffdir/buffer ]; then
    buffexe=$buffdir'/buffer';
   fi
   if [ -r $buffdir/buffer/bin/glnx86/buffer ]; then
	 buffexe=$buffdir'/buffer/bin/glnx86/buffer';
   fi
   if [ -r $buffdir/buffer/glnx86/buffer ]; then
	 buffexe=$buffdir'/buffer/glnx86/buffer';
   fi
else # Mac
   buffexe=$buffdir'/buffer/bin/buffer';
   if [ -r $buffdir/buffer/bin/maci/buffer ]; then
	 buffexe=$buffdir'/buffer/bin/maci/buffer'
   fi
   if [ -r $buffdir/buffer/maci/buffer ]; then
	 buffexe=$buffdir'/buffer/maci/buffer'
   fi
fi
$buffexe 
