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
import linear
import pickle

dname  ='training_data'
cname  ='clsfr'

trlen_ms = 3000
spatialfilter='car'

#load the trained classifier
if os.path.exists(cname+'.pk'):
    f     =pickle.load(open(cname+'.pk','rb'))
    goodch     = f['goodch']
    freqbands  = f['freqbands']
    valuedict  = f['valuedict']
    classifier = f['classifier']
    fs         = f['fSample']

# invert the value dict to get a key->value map
ivaluedict = { k:v for k,v in valuedict.items() }
    
# connect to the buffer, if no-header wait until valid connection
ftc,hdr=bufhelp.connect()

# clear event history
pending = []
while True:
    # wait for data after a trigger event
    #  exitevent=None means return as soon as data is ready
    #  N.B. be sure to propogate state between calls
    data, events, stopevents, pending = bufhelp.gatherdata(["stimulus.target"], trlen_ms, None, pending, milliseconds=True)
    
    # get all event type labels
    event_types = [e.type[0] for e in events] 
    
    # stop processing if needed
    if "stimulus.feedback" in event_types:
        break

    # get data in correct format
    data = np.transpose(data)

    # 1: detrend
    data = preproc.detrend(data)
    # 2: bad-channel removal (as identifed in classifier training)
    data = data[goodch,:,:]
    # 3: apply spatial filter (as in classifier training)
    data = preproc.spatialfilter(data,type=spatialfilter)
    # 4: map to frequencies (TODO: check fs matches!!)
    data,freqs = preproc.powerspectrum(data,dim=1,fSample=fs)
    # 5: select frequency bins we want
    data,freqIdx=preproc.selectbands(data,dim=1,band=freqbands,bins=freqs)
    # 6: apply the classifier, get raw predictions
    X2d = np.reshape(data,(-1,data.shape[2])).T # sklearn needs data to be [nTrials x nFeatures]
    fraw = classifier.predict(X2d)
    # 7: map from fraw to event values
    predictions = [ ivaluedict[round(i)] for i in fraw ]
    # send the prediction events
    for pred in predictions:
        bufhelp.sendEvent("classifier.prediction",pred)
        