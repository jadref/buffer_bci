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

#load the trained classifier
if os.path.exists(cname+'.pk'):
    f     =pickle.load(open(cname+'.pk','rb'))
    goodch     = f['goodch']
    freqIdx    = f['freqIdx']
    valuedict  = f['valuedict']
    classifier = f['classifier']

# invert the value dict to get a key->value map
ivaluedict = { k:v for k,v in valuedict.items() }
    
# connect to the buffer, if no-header wait until valid connection
ftc,hdr=bufhelp.connect()

while True:
    # wait for data after a trigger event
    #  exitevent=None means return as soon as data is ready
    #  N.B. be sure to propogate state between calls
    data, events, stopevents, pending = bufhelp.gatherdata(["stimulus.target"], trlen_ms, None, pending, milliseconds=True)

    # stop processing if needed
    if isinstance(stopevents, list) and any(["stimulus.feedback" in x.type for x in stopevents]):
        break
    elif "stimulus.feedback" in stopevents.type:
        break

    # 1: detrend
    data = preproc.detrend(data)
    # 2: bad-channel removal (as identifed in classifier training)
    data = data[goodch,:,:]
    # 3: apply spatial filter (as in classifier training)
    data = preproc.spatialfilter(data,type=spatialfilter)
    # 4: map to frequencies (TODO: check fs matches!!)
    data,freqs = preproc.powerspectrum(data,dim=1,fSample=fs)
    # 5: select frequency bins we want
    data=data[:,freqIdx,:]
    freqs=freqs[freqIdx]
    # 6 : bad-trial removal
    # 7: apply the classifier, get raw predictions
    fraw = classifier.predict(data)
    # 8: map from fraw to event values
    predictions = [ ivaluedict[round(i)] for i in fraw ]
    # send the prediction events
    for pred in predictions:
        bufhelp.sendEvent("classifier.prediction",pred)
