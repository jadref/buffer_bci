#!/usr/bin/env python3
# Set up imports and paths
import sys, os
# Get the helper functions for connecting to the buffer
try:     pydir=os.path.dirname(__file__)
except:  pydir=os.getcwd()    
sigProcPath = os.path.join(os.path.abspath(pydir),'../../python/signalProc')
sys.path.append(sigProcPath)
import bufhelp 
import pickle
import h5py

# connect to the buffer, if no-header wait until valid connection
ftc,hdr=bufhelp.connect()

# grab data 
data, events, stopevents, pending = bufhelp.gatherdata()

# save the calibration data
pickle.dump({"events":events,"data":data,'hdr':hdr}, open(dname+'.pk','wb'))#N.B. to pickle open in binary mode

