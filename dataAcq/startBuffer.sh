#!/bin/bash
buffdir=`dirname $0`
outdir=

# use GUI to update the save location
if [ -x $buffdir/getBufferSaveDir.py ] && [ ! -z `which python` ]; then
   outdir=`python $buffdir/getBufferSaveDir.py`;
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
	 if [ -r $outdir ] ; then # already exists?  add postfix
		  outdir=${outdir}_1
	 fi
fi

logfile=${outdir}.log
echo outdir: $outdir
mkdir -p "$outdir"
# Identify the OS and search for the appropriate executable
if [[ `uname -s` == 'Linux'* ]]; then
	 if  [ "`uname -a`" == 'armv6l' ]; then
		  arch='raspberrypi';
    else
		  arch='glnx86';
   fi
   buffexe=$buffdir'/buffer/bin/saving_buffer_glx32';
   if [ -r $buffdir/recording ]; then
      buffexe=$buffdir'/recording';
   fi
elif [[ `uname -s` = 'MINGW'* ]]; then
	 arch='win32'
	 buffexe=$bufdir'/buffer/win32/demo_buffer_unix'
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
echo $buffexe ${outdir}/raw_buffer

# turn return into carriage return to stop endless scrolling of the window
if [ -z `which tr` ]; then
  $buffexe "${outdir}"/raw_buffer $@
else
  $buffexe "${outdir}"/raw_buffer $@ | tr '\n' '\r'
fi
