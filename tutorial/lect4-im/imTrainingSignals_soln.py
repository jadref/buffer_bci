#!/usr/bin/env python3
# Set up imports and paths
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import sys, os
import numpy as np
from time import sleep, time
from random import shuffle
bufhelpPath = "../../python/signalProc"
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),bufhelpPath))
import bufhelp
import preproc
import linear
import pickle
import h5py


dname  ='training_data';
cname  ='clsfr';

print("Training classifier")
if os.path.exists(dname+'pk'):
    f     =pickle.load(open(dname+'pk','r'))
    data  =f['data']
    events=f['events']
    hdr   =f['hdr']
if os.path.exists(dname+'.mat'):
    f     = h5py.File(dname+'.mat','r')
    data  =f['data']
    events=f['events']
    hdr   =f['hdr']
    
# 1: detrend
data        = preproc.detrend(data)
# 2: bad-channel removal
data, badch = preproc.badchannelremoval(data)
# 3: apply spatial filter
data        = preproc.spatialfilter(data,type='car')
# 4 & 5: map to frequencies and select frequencies of interest
data        = preproc.spectralfilter(data, (8,10,28,30), hdr.fSample)
# 6 : bad-trial removal
data, events, badtrials = preproc.badtrailremoval(data, events)
# 7: train classifier, default is a linear-least-squares-classifier
mapping = {('stimulus.tgtFlash', '0'): 0, ('stimulus.tgtFlash', '1'): 1}
classifier = linear.fit(data,events,mapping)

# save the trained classifer
pickle.dump({'classifier':classifier,'mapping':mapping},open(cname+'.pk','w'))
# also as hdf5 / mat -v7.3
f = h5py.File(cname+'.mat','w')
f.create_dataset('classifier',data=classifier)
f.create_dataset('mapping',data=mapping)
