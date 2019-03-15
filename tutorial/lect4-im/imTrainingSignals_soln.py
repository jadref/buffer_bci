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
y = [e.value[0] for e in events] # get class labels from events
y = np.array(y) 

# 1: detrend
data        = preproc.detrend(data)

# 2: bad-channel removal
goodch, badch = preproc.outlierdetection(data);
data = data[goodch,:,:];

# 3: apply spatial filter
data        = preproc.spatialfilter(data,type='car')

# 4: map to frequencies 
data = preproc.fftfilter(data, 1, [8,10,28,30], fs)

# 6 : bad-trial removal
goodtr, badtr = preproc.outlierdetection(data,dim=2)
data = data[:,:,goodtr]
y = y[goodtr]

# 7: train classifier, default is a linear-least-squares-classifier
clsfr = sklearn.linear_model.RidgeCV(store_cv_values=True)
X2d = np.reshape(data,(-1,data.shape[2])).T # sklearn needs x to be [nTrials x nFeatures]
clsfr.fit(X2d,y)
print("MSSE=%g"%np.mean(clsfr.cv_values_))

# save the trained classifer
print('Saving clsfr to : %s'%(cname+'.pk'))
pickle.dump({'classifier':clsfr},open(cname+'.pk','wb'))
