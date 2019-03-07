#!/usr/bin/env python3
# Set up imports and paths
bufferpath = "../../dataAcq/buffer/python"
sigProcPath = "../signalProc"
import numpy as np
import sys
from time import sleep, time
import os
bufhelpPath = "../../python/signalProc"
utilitiesPath = "../../python/utilities"
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),bufhelpPath))
import bufhelp
import preproc
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),utilitiesPath))
import readCapInf
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),sigProcPath))
plottingPath= '../../python/plotting'
try:
    pydir=os.path.dirname(__file__)
except:
    pydir=os.getcwd()
sys.path.append(os.path.join(os.path.abspath(pydir),plottingPath))
from image3d import *

# init connection to the buffer
ftc,hdr=bufhelp.connect();

#define variables
trlen_samp = 50
nSymbols = 2
nr_channels = 4 # in debug mode
erp = np.zeros((nr_channels,trlen_samp,nSymbols))
nTarget = np.zeros((nSymbols,1))

Cname,latlong,xy,xyz,capfile= readCapInf.readCapInf('sigproxy_with_TRG')
ylabel = 'time(s)'
yvals = np.arange(0,trlen_samp);

fig=plt.figure()

state = []
endTest = False
while endTest is False:
    # grab data after every t:'stimulus' event until we get a {t:'stimulus.training' v:'end'} event 
    data, events, stopevents = bufhelp.gatherdata(["stimulus","experiment"],trlen_samp,("sequence","end"), milliseconds=False)

    for ei in np.arange(len(events)-1,-1,-1):
        ev = events[ei]
        # check for exit event
        if (ev.type == "experiment") and (ev.value == "end"):
            endTest = True
            print("end experiment")
            break
        
        # update ERP
        if ev.value is '+':
            classlabel = 1
        else:
            classlabel  = 0
        erp[:,:,classlabel] = (erp[:,:,classlabel]*nTarget[classlabel] + np.transpose(data[ei]))/(nTarget[classlabel]+1);
        nTarget[classlabel]= nTarget[classlabel]+1;

        # detrend erp, so we can see stuff
        erp = preproc.detrend(erp)

    image3d(erp)  # plot the ERPs
    plt.show()




