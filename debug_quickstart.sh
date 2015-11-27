#!/bin/bash
dataacq='java';
if [ $# -gt 0 ]; then datacq=$1; fi


echo Starting the non-saving java buffer server \(background\)
dataAcq/startJavaNoSaveBuffer.sh &
bufferpid=$!
echo buffpid=$bufferpid
sleep 3


echo Starting the data acquisation device $datacq \(background\)
if [ $datacq == 'audio' ]; then
  dataAcq/startJavaAudio.sh localhost 2 &
elif [ $datacq == 'matlab' ]; then
  dataAcq/startMatlabSignalProxy.sh &
else
  dataAcq/startJavaSignalproxy.sh &
fi
dataacqpid=$!


echo dataacqpid=$dataacqpid
echo Starting the default signal processing function \(background\)
signalProc/startSigProcBuffer.sh &
sigprocpid=$!


echo Starting the event viewer
dataAcq/startJavaEventViewer.sh
kill $bufferpid
kill $dataacqpid
kill $sigprocpid
