#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
source ../utilities/findMatlab.sh
fname=$1;
if [ ${fname:0:1}X != "'"X ]; then fname="'$fname'"; fi
if [[ $matexe == *matlab ]]; then  args=-nodesktop; fi
cat <<EOF | $matexe $args
buffer_fileproxy([],[],$fname);
quit;
EOF
# Note: to call with arguments you must *double-quote* the arguments....
exit;

#----------------------------------------------------------------
# Note nothing below this line is actually used!!!!
buffdir=`dirname $0`
if [ `uname -s` == 'Linux' ]; then
	 if  [ "`uname -a`" == 'armv6l' ]; then
		  arch='raspberrypi'
    else
		  arch='glnx86';
   fi
else # Mac
	 arch='maci'
fi
buffexe=$buffdir'/buffer/bin/playback';
if [ -r $buffdir/playback ]; then
    buffexe=$buffdir'/playback';
fi
if [ -r $buffdir/buffer/bin/${arch}/playback ]; then
	 buffexe=$buffdir'/buffer/bin/${arch}/playback';
fi
if [ -r $buffdir/buffer/${arch}/playback ]; then
	 buffexe=$buffdir'/buffer/${arch}/playback';
fi
$buffexe $@ > $logfile 