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
#sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),utilitiesPath))
#import readCapInf
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

#Cname,latlong,xy,xyz=readCapInf('sigproxy_with_TRG.txt')
Cnames = ["1/f","noise1","sin10.0Hz","TRG"]
Cpos = [[23, 90], [-46, 0], [46, 0], [23, -90]]
ylabel="time (s)"
yvals = np.arange(0,trlen_samp)

fig=plt.figure()

state = []
endTest = False
while endTest is False:
    # grab data after every t:'stimulus' event until we get a {t:'stimulus.training' v:'end'} event 
    data, events, stopevents = bufhelp.gatherdata(["stimulus","experiment"],trlen_samp,("sequence","end"), milliseconds=False)

    for ei in range(len(events),0):
        ev = events[ei]
        # check for exit event
        if (ev.type is "experiment") and (ev.value is "end"):
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
        image3d(erp,0,plotpos=Cpos,xvals=Cnames,ylabel=ylabel,yvals=yvals) # plot the ERPs




