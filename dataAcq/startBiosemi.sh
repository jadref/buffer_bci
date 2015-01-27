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
	 cd $buffdir'/buffer/bin/glnx86';
fi
   if [ -r $buffdir/buffer/glnx86/biosemi2ft ]; then
	 cd $buffdir'/buffer/glnx86';
   fi
   export LD_LIBRARY_LOADPATH=${LD_LIBRARY_LOADPATH}:`pwd`   
   buffexe='./biosemi2ft'
else # Mac
   if [ -r $buffdir/buffer/bin/maci/biosemi2ft ]; then
    # Argh, annoyingly the driver only works if run in it's own directory
    cd $buffdir/buffer/bin/maci
   fi
   if [ -r $buffdir/buffer/maci/biosemi2ft ]; then
    # Argh, annoyingly the driver only works if run in it's own directory
    cd $buffdir/buffer/maci
   fi
   # add exec directory to library load path
   export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:`pwd`
   buffexe='./biosemi2ft';
fi
$buffexe ${buffdir}/biosemi.cfg $outfile > $logfile 

if [ $? == 1 ] ; then
	 echo Couldnt start the AMP driver.  Possible reasons
	 echo 1) The amplifier isnt connected or turned on?
	 echo 2) You cannot read the USB device.  On linux try: sudo ./startBiosemi.sh
fi
