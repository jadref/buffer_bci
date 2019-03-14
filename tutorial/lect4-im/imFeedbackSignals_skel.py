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
    data, events, stopevents, state = bufhelp.gatherdata(["stimulus.target"],trlen_ms,[("stimulus.feedback","end")], milliseconds=True)

    # YOUR CODE HERE #
    
    # apply classifier, default is a linear-least-squares-classifier        
    predictions = linear.predict(data)
    
    # send the prediction events
    for pred in predictions:
        bufhelp.sendEvent("classifier.prediction",pred)
