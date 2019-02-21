#!/usr/bin/env python
import os, sys
# Path of the folder containing the buffer client                                              
try:
    pydir=os.path.dirname(__file__)
except:
    pydir=os.getcwd()

sigProcPath = '../../python/signalProc'
sys.path.append(os.path.join(os.path.abspath(pydir),sigProcPath))
import preproc
import linear
import numpy as np
plottingPath= '../../python/plotting'
sys.path.append(os.path.join(os.path.abspath(pydir),plottingPath))
from image3d import *
from scipy.io import loadmat

#load the datafile, and extract the variables                                                  
data=loadmat('ERSPdata.mat')
X     =data['X']; print("X= [channels x timepoints x trials]");print(X.shape)
Y     =data['Y'].reshape(-1); print("Y=[trials]");print(Y.shape)
fs    =float(data['fs'][0])
Cnames=data['Cnames'].reshape(-1); 
Cnames=np.array([item for sublist in Cnames for item in sublist]) #flatten the list of lists of names and make array
print("Channel names : ");print(Cnames)
Cpos  =data['Cpos']; print("Cpos= [ 3 x channels]");print(Cpos.shape);


# plot the data                                                                                
image3d(X[:,:,1:3],0,plotpos=Cpos);

# plot the class averages
erp=np.stack((X[:,:,Y>0].mean(2),X[:,:,Y<=0].mean(2)),2) #compute the ERP
image3d(erp,0,plotpos=Cpos,xvals=Cnames); # plot the ERPs

# define some utility functions to simplify plotting of data
ylabel='time (s)'
yvals =np.arange(0,X.shape[1])/fs  # element labels for 2nd dim of X

def plotTrials(X,trls):
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
    fig=plt.figure(1,figsize=(12, 12))
    plotTrials(X,range(3)) # single trial

    fig=plt.figure(2,figsize=(12, 12))
    plotERP(X,Y) # class averages

# plot a subset of single-trials
plt.figure(1,figsize=(12, 12));
plotTrials(X,range(3));


# plot the grand average's per condition
plt.figure(2,figsize=(12, 12))
plotERP(X,Y);


#-------------------------------------------------------------------
#  Run the standard pre-processing and analysis pipeline
# 1: detrend
X        = preproc.detrend(X)
updatePlots();


# 2: bad-channel removal
goodch, badch = preproc.outlierdetection(X);
X = X[goodch,:,:];
Cnames=Cnames[goodch];
Cpos=Cpos[:,goodch];
updatePlots()


# 3: apply spatial filter
X        = preproc.spatialfilter(X,type='car')
updatePlots();


# Map to frequency domain, only keep the positive frequencies
X,freqs = preproc.powerspectrum(X,dim=1,fSample=fs)
yvals = freqs; # ensure the plots use the right x-ticks
ylabel='freq (Hz)'
updatePlots()


# 5 : select the frequency bins we want
X,freqIdx=preproc.selectbands(X,dim=1,band=[8,10,28,30],bins=freqs)
freqs=freqs[freqIdx]
yvals=freqs
updatePlots()


# 6 : bad-trial removal, trials in dim=2
goodtr, badtr = preproc.outlierdetection(X,dim=2)
X = X[:,:,goodtr]
Y = Y[goodtr]
updatePlots()


# 7: train linear least squares classifier, with cross-validation
import sklearn
clsfr = sklearn.linear_model.RidgeCV(store_cv_values=True)
X2d = np.reshape(X,(-1,X.shape[2])).T # sklearn needs x to be [nTrials x nFeatures]
clsfr.fit(X2d,Y)
print("MSSE=%g"%np.mean(clsfr.cv_values_))

# plot the classifier weight vector
W = clsfr.coef_
W = np.reshape(clsfr.coef_,(X.shape[0],X.shape[1])) 
image3d(W,0,plotpos=Cpos,xvals=Cnames,yvals=freqs);
