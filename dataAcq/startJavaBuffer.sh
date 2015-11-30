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

mkdir -p "$outdir"

echo Starting: ${buffdir}/buffer/java/BufferServer.jar ${outdir}/raw_buffer $@
exec java -jar ${buffdir}/buffer/java/BufferServer.jar ${outdir}/raw_buffer $@
