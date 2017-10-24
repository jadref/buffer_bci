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
    classifier = f['classifier']


# connect to the buffer, if no-header wait until valid connection
ftc,hdr=bufhelp.connect()

while True:
    # wait for data after a trigger event
    data, events, stopevents = bufhelp.gatherdata(["stimulus.target"],trlen_ms,[("stimulus.feedback","end")], milliseconds=True)

    # stop processing if needed
    if isinstance(stopevents, list) and any(["stimulus.feedback" in x.type for x in stopevents]):
        break
    elif "stimulus.feedback" in stopevents.type:
        break

    # 1: detrend
    data = preproc.detrend(data)
    # 2: bad-channel removal
    data, badch = preproc.badchannelremoval(data)
    # 3: apply spatial filter
    data = preproc.spatialfilter(data)
    # 4 & 5: map to frequencies and select frequencies of inter
    data = preproc.spectralfilter(data, (8,10,28,30), hdr.fSample)
    # 6 : bad-trial removal
    data2, events, badtrials = preproc.badtrailremoval(data, events)
    # 7: train classifier, default is a linear-least-squares-classifier        
    predictions = linear.predict(data)
    # send the prediction events
    for pred in predictions:
        bufhelp.sendEvent("classifier.prediction",pred)
