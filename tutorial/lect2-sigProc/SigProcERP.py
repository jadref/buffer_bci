#!/bin/python3
import os, sys
# Path of the folder containing the buffer client
try:
    pydir=os.path.dirname(__file__)
except:
    pydir=os.getcwd()
    
sigProcPath = '../../python/signalProc'
sys.path.append(os.path.join(os.path.abspath(pydir),sigProcPath))
import bufhelp
import preproc
#import linear
import sklearn
import skwrap
plottingPath= '../../python/plotting'
sys.path.append(os.path.join(os.path.abspath(pydir),plottingPath))
from image3d import *
from scipy.io import loadmat

#load the datafile, and extract the variables
data=loadmat('ERPdata.mat')
X     =data['X']
Y     =data['Y'].reshape(-1) # ensure is 1d
fs    =data['fs'][0] # ensure is scalar
Cnames=data['Cnames']
Cnames=[item for sublist in Cnames for item in sublist] #flatten the list of lists of names
Cpos  =data['Cpos']

ylabel='time (s)'
yvals =range(0,X.shape[1])/fs  # element labels for 2nd dim of X

def plotTrials(X,trls=range(3)):
    'Plot the single-trial data'
    global Cnames, Cpos, ylabel, yvals
    image3d(X[:,:,1:3],0,plotpos=Cpos,xvals=Cnames,ylabel=ylabel,yvals=yvals)

def plotERP(X,Y):
    'plot the class averages'
    global Cnames, Cpos, ylabel, yvals
    erp=np.stack((X[:,:,Y>0].mean(2),X[:,:,Y<=0].mean(2)),2) #compute the ERP
    image3d(erp,0,plotpos=Cpos,xvals=Cnames,ylabel=ylabel,yvals=yvals) # plot the ERPs

def updatePlots():
    global X,Y
    # Plot the raw data
    fig=plt.figure()
    plotTrials(X) # single trial

    fig=plt.figure()
    plotERP(X,Y) # class averages

#-------------------------------------------------------------------
#  Run the standard pre-processing and analysis pipeline
# 1: detrend
X        = preproc.detrend(X)
updatePlots()

# 2: bad-channel removal, channels in dim=0
goodch, badch = preproc.outlierdetection(X)
X = X[goodch,:,:]
Cnames=Cnames[goodch]
Cpos=Cpos[:,goodch]
updatePlots()

# 3: apply spatial filter
X = preproc.spatialfilter(X,type='car')
updatePlots()

# 4 & 5: map to frequencies and select frequencies of interest
X = preproc.spectralfilter(X, (8,10,28,30), hdr.fSample)
updatePlots()

# 6 : bad-trial removal, trials in dim=2
goodtr, badtr = preproc.outlierdetection(X,dim=2)
X = X[:,:,goodtr]
Y = Y[goodtr]
updatePlots()

# 7: train classifier, default is a linear-least-squares-classifier
mapping = {('stimulus.tgtFlash', '0'): 0, ('stimulus.tgtFlash', '1'): 1}
classifier = linear.fit(X,events,mapping)
