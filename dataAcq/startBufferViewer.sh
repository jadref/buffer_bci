#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
#cd ~/projects/bci/buffer_bci/dataAcq/ft_buffer/realtime/bin;
if [ `uname -s` == 'Linux' ]; then
	 if  [ "`uname -a`" == 'armv6l' ]; then
		  arch='raspberrypi'
    else
		  arch='glnx86'
   fi
else
   arch='maci'
fi
./buffer/${arch}/bufferViewer $@
