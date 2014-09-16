#!/bin/bash
outDir=~/source/buffer_bci
if [ ! -r $outDir ] ; then mkdir -p $outDir; 
#else
#  \rm -rf $outDir/*
fi
echo Creating buffer_bci directory in : $outDir
#cpio -p -d ~/temp/imaginedMovements < imaginedMovements.dep
cat buffer_bci.dep | while read source dest; do
	 fn=`eval echo $source`
	echo $fn $dest
	if [ ! -r $outDir/$dest ]; then mkdir -p $outDir/$dest; fi
	 cp $fn $outDir/$dest
done
# remove tempory files
find $outDir -name '*~' -exec rm {} \;
find $outDir -name '#*' -exec rm {} \;
find $outDir -name '*.bak' -exec rm {} \;
# remove data files
find $outDir -name 'tutorial' -prune -o -name '*.mat' -exec rm {} \;
find $outDir -name 'tutorial' -prune -o -name '*.pdf' -exec rm {} \;
find $outDir -name '*.log' -exec rm {} \;
find $outDir -name 'training_data*' -exec rm {} \;
find $outDir -name 'octave-core' -exec rm {} \;
find $outDir -name 'matlab*crash*dump' -exec rm {} \;
find $outDir \( -name '*.pyc' -o -name '*.o' \) -exec rm {} \;
# make a .zip archive
cd $outDir/../;
zip -r buffer_bci.zip buffer_bci/*