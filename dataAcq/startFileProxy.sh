#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
fname=$1;
if [ ${fname:0:1} != "'" ]; then fname="'$fname'"; fi
cat <<EOF | $matexe -nodesktop  -nosplash
args={$2 $3 $4 $5 $6 $7 $8 $9 ${10}}
buffer_fileproxy([],[],$fname,args{:});
quit;
EOF
# Note: to call with arguments you must *double-quote* the arguments....
exit;
buffdir=`dirname $0`
if [ `uname -s` == 'Linux' ]; then
   buffexe=$buffdir'/buffer/bin/playback';
   if [ -r $buffdir/playback ]; then
    buffexe=$buffdir'/playback';
   fi
   if [ -r $buffdir/buffer/bin/glnx86/playback ]; then
	 buffexe=$buffdir'/buffer/bin/glnx86/playback';
   fi
   if [ -r $buffdir/buffer/glnx86/playback ]; then
	 buffexe=$buffdir'/buffer/glnx86/playback';
   fi
else # Mac
   buffexe=$buffdir'/buffer/bin/playback';
   if [ -r $buffdir/buffer/bin/maci/playback ]; then
	 buffexe=$buffdir'/buffer/bin/maci/playback'
   fi
   if [ -r $buffdir/buffer/maci/playback ]; then
	 buffexe=$buffdir'/buffer/maci/playback'
   fi
fi
$buffexe $@ > $logfile 