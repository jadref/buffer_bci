echo Starting the buffer server (background)
dataAcq/startJavaBuffer.sh &
echo Starting the simulated data acquisation device (background)
dataAcq/startJavaSignalProxy.sh &
echo Starting the default signal processing function (background)
signalProc/startSigProcBuffer.sh &
echo Starting the event viewer
dataAcq/startJavaEventViewer.sh
