#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir=`dirname $0`

dataacq='mobita';
if [ $# -gt 0 ]; then dataacq=$1; fi
sigproc=0;
if [ $# -gt 1 ]; then sigproc=$2; fi

echo Starting the java buffer server \(background\)
dataAcq/startJavaBuffer.sh &
bufferpid=$!
echo buffpid=$bufferpid
sleep 5


echo Starting the data acquisation device $dataacq \(background\)
if [ $dataacq == 'mobita' ]; then
  dataAcq/startMobita.sh localhost 2 &
elif [ $dataacq == 'biosemi' ]; then
  dataAcq/startBiosemi.sh &
else
  echo Dont recognise the eeg device type!
fi
dataacqpid=$!
echo dataacqpid=$dataacqpid

if [ $sigproc -eq 1 ]; then
  echo Starting the default signal processing function \(background\)
  matlab/signalProc/startSigProcBuffer.sh &
  sigprocpid=$!
fi


echo Starting the event viewer
dataAcq/startJavaEventViewer.sh
kill $bufferpid
kill $dataacqpid
kill $sigprocpid
