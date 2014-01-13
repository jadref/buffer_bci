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
   buffexe=$buffdir'/buffer/bin/saving_buffer_glx32';
   if [ -r $buffdir/recording ]; then
    buffexe=$buffdir'/recording';
   fi
   if [ -r $buffdir/buffer/bin/glnx86/recording ]; then
	 buffexe=$buffdir'/buffer/bin/glnx86/recording';
   fi
   if [ -r $buffdir/buffer/glnx86/recording ]; then
	 buffexe=$buffdir'/buffer/glnx86/recording';
   fi
else # Mac
   buffexe=$buffdir'/buffer/bin/saving_buffer';
   if [ -r $buffdir/buffer/bin/maci/recording ]; then
	 buffexe=$buffdir'/buffer/bin/maci/recording'
   fi
   if [ -r $buffdir/buffer/maci/recording ]; then
	 buffexe=$buffdir'/buffer/maci/recording'
   fi
fi
$buffexe $outdir > $logfile 
