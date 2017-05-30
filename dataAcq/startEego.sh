#! /usr/bin/env bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir="$( pwd )"
echo $buffdir
exedir=${buffdir}/buffer/bin
buffexe=eego2ft;
if [ `uname -s` == 'Linux' ]; then
   if [ -r $buffdir/buffer/bin/glnx86/$buffexe ]; then
	 exedir=$buffdir'/buffer/bin/glnx86';
fi
   if [ -r $buffdir/buffer/glnx86/$buffexe ]; then
	 exedir=$buffdir'/buffer/glnx86';
   fi
   export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${exedir}
else # Mac
   if [ -r $buffdir/buffer/bin/maci/$buffexe ]; then
    exedir=$buffdir/buffer/bin/maci
   fi
   if [ -r $buffdir/buffer/maci/$buffexe ]; then
    exedir=$buffdir/buffer/maci
   fi
   # add exec directory to library load path
   export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:${exedir}   
fi

#identify the config file to use
if [ -r ${buffdir}/${buffexe%2ft}.cfg ]; then
    configFile=${buffdir}/${buffexe%2ft}.cfg
else
    configFile=-
fi
${exedir}/${buffexe} ${configFile} $*

if [ $? == 1 ] ; then
	 echo Couldnt start the AMP driver.  Possible reasons
	 echo 1\) The amplifier isnt connected or turned on?
	 echo 2\) You cannot read the USB device.  On linux try: sudo ./${BASH_SOURCE[0]}
fi
