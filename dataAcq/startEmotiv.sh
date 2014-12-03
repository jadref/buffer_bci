#! /usr/bin/env bash
# Get the *Absolute* path to where this script is running
buffdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
bciroot=~/output
subject='test';
if [ $# -gt 0 ]; then subject=$1; fi 
session=`date +%y%m%d`
if [ $# -gt 1 ]; then session=$2; fi
block=`date +%h%m`_$$
if [ $# -gt 2 ]; then block=$2; fi
outfile=$bciroot/$subject/$session/$block/raw_gdf/$subject.gdf
logfile=$bciroot/$subject/$session/$block.log
echo outdir: $outdir
echo logfile : $logfile
mkdir -p $bciroot/$subject/$session/$block/raw_gdf
touch $logfile

execname=emotive2ft
if [ `uname -s` == 'Linux' ]; then
	 if  [ "`uname -a`" == 'armv6l' ]; then
		  arch='raspberrypi'
    else
		  arch='glnx86';
   fi
else # Mac
   arch='maci'
fi
buffexe="$buffdir/buffer/bin/${execname}";
if [ -r $buffdir/buffer/bin/${arch}/${execname} ]; then
	 buffexe="$buffdir/buffer/bin/${arch}/${execname}";
fi
if [ -r $buffdir/buffer/${arch}/${execname} ]; then
	 buffexe="$buffdir/buffer/${arch}/${execname}";
fi
if [ -r $buffdir/buffer/${arch}/emokit2ft ] ; then
	 buffexe="$buffdir'/buffer/${arch}/emokit2ft";
fi

if [ ${arch} == 'maci' ]; then
    # Argh, annoyingly the emotive driver only works if run in it's own directory
    cd ${buffexe%/*}
	 export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:${buffexe%/*}
	 buffexe=./${execname}
fi

$buffexe ${buffdir}/emotiv.cfg $outfile > $logfile 
