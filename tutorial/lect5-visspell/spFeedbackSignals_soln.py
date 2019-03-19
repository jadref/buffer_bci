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

trlen_ms = 600
spatialfilter='car'

#load the trained classifier
if os.path.exists(cname+'.pk'):
    f     =pickle.load(open(cname+'.pk','rb'))
    goodch     = f['goodch']
    freqbands  = f['freqbands']
    valuedict  = f['valuedict']
    classifier = f['classifier']

# invert the value dict to get a key->value map
ivaluedict = { k:v for k,v in valuedict.items() }
    
# connect to the buffer, if no-header wait until valid connection
ftc,hdr=bufhelp.connect()
fs = hdr.fSample

pending = []
while True:
    # wait for data after a trigger event
    #  exitevent=None means return as soon as data is ready
    #  N.B. be sure to propogate state between calls
    data, events, stopevents, pending = bufhelp.gatherdata(["stimulus.flash"], trlen_ms, None, pending, milliseconds=True, verbose=True)
    
    # get all event type labels
    event_types = [e.type[0] for e in events] 
    
    # stop processing if needed
    if "stimulus.feedback" in event_types:
        break

    print("Applying classifier to %d events"%(len(events)))
    
    # get data in correct format
    data = np.transpose(data) # make it [d x tau]
    
    # 1: detrend
    data = preproc.detrend(data)
    # 2: bad-channel removal (as identifed in classifier training)
    data = data[goodch,:,:]
    # 3: apply spatial filter (as in classifier training)
    data = preproc.spatialfilter(data,type=spatialfilter)
    # 4 & 5: spectral filter (TODO: check fs matches!!)
    data = preproc.fftfilter(data, 1, freqbands, fs)
    # 6 : bad-trial removal
    # 7: apply the classifier, get raw predictions
    X2d  = np.reshape(data,(-1,data.shape[2])).T # sklearn needs data to be [nTrials x nFeatures]
    fraw = classifier.predict(X2d)
    # 8: map from fraw to event values (note probably not necessary here!)    
    #predictions = [ ivaluedict[round(i)] for i in fraw ]
    # send the prediction events
    for i,f in enumerate(fraw):
        print("%d) {%s}=%f(raw)\n"%(i,str(events[i]),f))
        bufhelp.sendEvent("classifier.prediction",f)
