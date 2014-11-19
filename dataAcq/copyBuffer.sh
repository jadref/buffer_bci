#!/bin/bash
platform=`uname`
if [ $platform == 'Linux' ] ; then
  bindir=glnx86
fi
if [ $platform == 'Darwin' ] ; then
  bindir=maci
fi
curDir=$PWD;
if [ ! -d $curDir/buffer ]; then
  mkdir $curDir/buffer
fi
#if [ ! -d $curDir/buffer/bin ]; then
#  mkdir $curDir/buffer/bin
#fi
if [ -r $curDir/ft_buffer/realtime ]; then
  ftdir=$curDir/ft_buffer/realtime
elif [[ $curDir =~ .*BCI_Code.* ]]; then
  # find ft_dir relative to here
  bcicodedir=${curDir%BCI_Code*};
  bcicodedir=${bcicodedir}/BCI_Code
  ftdir     =$bcicodedir/external_toolboxes/fieldtrip/realtime
else
  if [ -d ~/source ]; then
     bcicodedir=~/source
     if [ -d ${bcicodedir}/mmmcode ]; then
        ftdir=$bcicodedir/mmmcode/BCI_Code/external_toolboxes/fieldtrip/realtime
	ftdir=$bcicodedir/mmmcode/BCI_Code/toolboxes/brainstream_mds/toolboxes/fieldtrip/realtime
     else
        ftdir=$bcicodedir/matfiles/toolboxes/fieldtrip/realtime
     fi
  fi
fi
cp ${ftdir}/src/buffer/matlab/buffer.* $curDir/buffer
#cp ${ftdir}/src/buffer/matlab/pthread* $curDir/buffer
cp -r ${ftdir}/src/external/pthread* $curDir/buffer
cp -r ${ftdir}/bin/* $curDir/buffer/
find $curDir/buffer -type d -name '.svn' -exec rm -r {} \;
