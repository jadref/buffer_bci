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
buffexe=$buffdir'/buffer/bin/emotiv2ft';
if [ `uname -s` == 'Linux' ]; then
   if [ -r $buffdir/buffer/bin/glnx86/emotiv2ft ]; then
	 buffexe=$buffdir'/buffer/bin/glnx86';
   fi
   if [ -r $buffdir/buffer/glnx86/emotiv2ft ]; then
	 buffexe=$buffdir'/buffer/glnx86';
   fi
	if [ ! -r $buffexe ] ; then
		 echo Can not find emotive2ft.  Falling back on 'startEmokit.sh'
		 startEmokit.sh $@
		 exit
	fi
else # Mac
   if [ -r $buffdir/buffer/bin/maci/emotiv2ft ]; then
    # Argh, annoyingly the emotive driver only works if run in it's own directory
    cd $buffdir/buffer/bin/maci
	 # add exec directory to library load path
	 export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$buffdir'/buffer/bin/maci'
   fi
   if [ -r $buffdir/buffer/maci/emotiv2ft ]; then
    # Argh, annoyingly the emotive driver only works if run in it's own directory
    cd $buffdir/buffer/maci
	 export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$buffdir'/buffer/maci'
   fi
   buffexe='./emotiv2ft'
fi
$buffexe ${buffdir}/emotiv.cfg $outfile > $logfile 
