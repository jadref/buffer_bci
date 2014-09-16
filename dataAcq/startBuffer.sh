#!/bin/bash
buffdir=`dirname $0`
outdir=

# use GUI to update the save location
if [ -x startBuffer.py ] && [ ! -z `which python` ]; then
   outdir=`python startBuffer.py`;
fi

# fall back code to compute save location
if [ -z $outdir ] ; then
	 bciroot=~/output
	 subject='test';
	 if [ $# -gt 0 ]; then subject=$1; fi 
	 session=`date +%y%m%d`
	 if [ $# -gt 1 ]; then session=$2; fi
	 block=`date +%H%M`
	 if [ $# -gt 2 ]; then block=$2; fi
	 outdir=$bciroot/$subject/$session/$block
fi

if [ -r $outdir ] ; then # already exists?  add postfix
  outdir=${outdir}_1
fi
logfile=${outdir}.log
echo outdir: $outdir
echo logfile : $logfile
mkdir -p $outdir
touch $logfile
if [ `uname -s` == 'Linux' ]; then
	 if  [ "`uname -a`" == 'armv6l' ]; then
		  arch='raspberrypi'
    else
		  arch='glnx86';
   fi
   buffexe=$buffdir'/buffer/bin/saving_buffer_glx32';
   if [ -r $buffdir/recording ]; then
      buffexe=$buffdir'/recording';
   fi
else # Mac
	 arch='maci'
   buffexe=$buffdir"/buffer/bin/saving_buffer";
fi
if [ -r $buffdir/buffer/bin/${arch}/recording ]; then
	 buffexe=$buffdir"/buffer/bin/${arch}/recording";
fi
if [ -r $buffdir/buffer/${arch}/recording ]; then
	 buffexe=$buffdir"/buffer/${arch}/recording";
fi
$buffexe ${outdir}/raw_buffer > $logfile 
