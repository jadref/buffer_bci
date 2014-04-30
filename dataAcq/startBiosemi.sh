#! /usr/bin/env bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $buffdir
bciroot=~/output
subject='test';
if [ $# -gt 0 ]; then subject=$1; fi 
session=`date +%y%m%d`
if [ $# -gt 1 ]; then session=$2; fi
block=`date +%h%m`_$$
if [ $# -gt 2 ]; then block=$2; fi
outfile=$bciroot/$subject/$session/$block/raw_gdf/$subject.gdf
logfile=$bciroot/$subject/$session/$block.log
echo outfile: $outfile
echo logfile : $logfile
mkdir -p $bciroot/$subject/$session/$block/raw_gdf
touch $logfile
buffexe=$buffdir'/buffer/bin/biosemi2ft';
if [ `uname -s` == 'Linux' ]; then
   if [ -r $buffdir/buffer/bin/glnx86/biosemi2ft ]; then
	 buffexe=$buffdir'/buffer/bin/glnx86/biosemi2ft';
   fi
   if [ -r $buffdir/buffer/glnx86/biosemi2ft ]; then
	 buffexe=$buffdir'/buffer/glnx86/biosemi2ft';
   fi
	if [ -r $buffdir/emokit/emokit2ft/emokit2ft ] ; then
	 buffexe=$buffdir'/emokit/emokit2ft/emokit2ft';
	fi
else # Mac
   if [ -r $buffdir/buffer/bin/maci/biosemi2ft ]; then
    # Argh, annoyingly the driver only works if run in it's own directory
    cd $buffdir/buffer/bin/maci
   # add exec directory to library load path
   export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$buffdir'/buffer/bin/maci'
   fi
   if [ -r $buffdir/buffer/maci/biosemi2ft ]; then
    # Argh, annoyingly the driver only works if run in it's own directory
    cd $buffdir/buffer/maci
	 # add exec directory to library load path
	 export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$buffdir'/buffer/maci'
   fi
   buffexe='./biosemi2ft';
fi
$buffexe ${buffdir}/biosemi.cfg $outfile > $logfile 