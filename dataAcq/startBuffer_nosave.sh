#!/bin/bash
buffdir=`dirname $0`
bciroot=~/output
subject='test';
if [ $# -gt 0 ]; then subject=$1; fi 
session=`date +%y%m%d`
if [ $# -gt 1 ]; then session=$2; fi
block=`date +%H%M`_$$
if [ $# -gt 2 ]; then block=$2; fi
outdir=$bciroot/$subject/$session/$block/raw_buffer
logfile=$bciroot/$subject/$session/$block.log
echo outdir: $outdir
echo logfile : $logfile
mkdir -p $bciroot/$subject/$session/$block
touch $logfile
if [ `uname -s` == 'Linux' ]; then
   buffexe=$buffdir'/buffer/bin/buffer';
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
$buffexe $outdir > $logfile 
