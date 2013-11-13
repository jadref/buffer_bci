#! /usr/bin/env bash
cd `dirname ${BASH_SOURCE[0]}`
%cd ~/BCI_code/toolboxes/brainstream_mds/toolboxes/fieldtrip/realtime/bin/maci/
buffdir=`dirname $0`
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
buffexe=$buffdir'/buffer/bin/emotiv2ft';
if [ `uname -s` == 'Linux' ]; then
   if [ -r $buffdir/buffer/bin/glnx86/emotiv2ft ]; then
	 buffexe=$buffdir'/buffer/bin/glnx86';
   fi
   if [ -r $buffdir/buffer/glnx86/emotiv2ft ]; then
	 buffexe=$buffdir'/buffer/glnx86';
   fi
	if [ -r $buffdir/emokit/emokit2ft/emokit2ft ] ; then
	 buffexe=$buffdir'/emokit/emokit2ft';
	fi
else # Mac
   if [ -r $buffdir/buffer/bin/maci/emotiv2ft ]; then
	 buffexe=$buffdir'/buffer/bin/maci';
	 # add exec directory to library load path
	 export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$buffdir'/buffer/bin/maci'
   fi
   if [ -r $buffdir/buffer/maci/emotiv2ft ]; then
	 buffexe=$buffdir'/buffer/maci';
	 export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$buffdir'/buffer/maci'
   fi
fi
# Argh, annoyingly the emotive driver only works if run in it's own directory
cd $buffexe
./emotiv2ft ${buffdir}/emotiv.cfg $outfile > $logfile 
