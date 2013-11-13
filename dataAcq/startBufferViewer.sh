#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
#cd ~/projects/bci/buffer_bci/dataAcq/ft_buffer/realtime/bin;
if [ `uname -s` == 'Linux' ]; then
   ./buffer/glnx86/bufferViewer
else
   ./buffer/maci/bufferViewer
fi
