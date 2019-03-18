#!/usr/bin/env python3
# Set up imports and paths
import sys, os
import numpy as np
# Get the helper functions for connecting to the buffer
try:     pydir=os.path.dirname(__file__)
except:  pydir=os.getcwd()    
sigProcPath = os.path.join(os.path.abspath(pydir),'../../python/signalProc')
sys.path.append(sigProcPath)
import bufhelp
import linear
import sklearn
import preproc
import pickle

dname  ='training_data'
cname  ='clsfr'

print("Training classifier")
if os.path.exists(dname+'.pk'):
    f     =pickle.load(open(dname+'.pk','rb'))
    data  =f['data']
    events=f['events']
    hdr   =f['hdr']
# try the hdf5 file
if not 'data' in dir() and os.path.exists(dname+'.h5'):
    import h5py
    f     = h5py.File(dname+'.mat','r')
    data  =f['data']
    events=f['events']
    hdr   =f['hdr']
# try the .mat file if all else fails
if not 'data' in dir() and os.path.exists(dname+'.mat'):
    from scipy.io import loadmat
    f     = loadmat(dname+'.mat')
    data  =f['data']
    events=f['events']
    hdr   =f['hdr']


#-------------------------------------------------------------------
#  Run the standard pre-processing and analysis pipeline

# get data in correct format
data = np.array(data)
data = np.transpose(data)
fs = hdr.fSample # sample rate

# 0: get class labels from events values
y = [e.value[0] for e in events] 
# convert to numeric labels
valuedict={} # dict to convert from event.values to numbers    
#y = np.array(y) # N.B. Only works with *NUMERIC* event values...
# get the unique values in y
valuedict = set(y)
# convert to dictionary
valuedict = { val:i for i,val in enumerate(valuedict) }
# use the dict to map from values to numbers
y    = np.array([ valuedict[val] for val in y ])


# 1: detrend
data        = preproc.detrend(data)

# 2: bad-channel removal
goodch, badch = preproc.outlierdetection(data);
data = data[goodch,:,:];

# 3: apply spatial filter
spatialfilter='car'
data        = preproc.spatialfilter(data,type=spatialfilter)

# 4: map to frequencies 
data,freqs = preproc.powerspectrum(data,dim=1,fSample=fs)

# 5 : select the frequency bins we want
freqbands   =[8,10,28,30]
data,freqIdx=preproc.selectbands(data,dim=1,band=freqbands,bins=freqs)

# 6 : bad-trial removal
goodtr, badtr = preproc.outlierdetection(data,dim=2)
data = data[:,:,goodtr]
y = y[goodtr]

# 7: train classifier, default is a linear-least-squares-classifier
clsfr = sklearn.linear_model.RidgeCV(store_cv_values=True)
X2d = np.reshape(data,(-1,data.shape[2])).T # sklearn needs data to be [nTrials x nFeatures]
clsfr.fit(X2d,y)
print("MSSE=%g"%np.mean(clsfr.cv_values_))

# save the trained classifer
# N.B. Be sure to save enough to apply the classifier later!!
print('Saving clsfr to : %s'%(cname+'.pk'))
pickle.dump({'classifier':clsfr,'fSample':fs,'spatialfilter':spatialfilter,'freqbands':freqbands,'goodch':goodch,'valuedict':valuedict},open(cname+'.pk','wb'))
