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
# 1: detrend
data        = preproc.detrend(data)
# 2: bad-channel removal
data, badch = preproc.badchannelremoval(data)
# 3: apply spatial filter
data        = preproc.spatialfilter(data,type='car')
# 4 : TODO: apply time-domain spectral filter
#data        = preproc.spectralfilter(data, (8,10,28,30), hdr.fSample)
# 6 : bad-trial removal
data, events, badtrials = preproc.badtrailremoval(data, events)
# 7: train classifier, default is a linear-least-squares-classifier
import linear
#mapping = {('stimulus.target', 0): 0, ('stimulus.target', 1): 1}
classifier = linear.fit(data,events)#,mapping)

# save the trained classifer
print('Saving clsfr to : %s'%(cname+'.pk'))
pickle.dump({'classifier':classifier},open(cname+'.pk','wb'))
# # Unfortunately doesn't work for objects...
# # also as hdf5 / mat -v7.3
# f = h5py.File(cname+'.mat','w')
# f.create_dataset('classifier',data=classifier)
# f.create_dataset('mapping',data=mapping)
