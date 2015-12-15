#!/bin/bash
dataacq='java';
if [ $# -gt 0 ]; then dataacq=$1; fi


echo Starting the non-saving java buffer server \(background\)
dataAcq/startJavaNoSaveBuffer.sh &
bufferpid=$!
echo buffpid=$bufferpid
sleep 3


echo Starting the data acquisation device $dataacq \(background\)
if [ $dataacq == 'audio' ]; then
  dataAcq/startJavaAudio.sh localhost 2 &
elif [ $dataacq == 'matlab' ]; then
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
