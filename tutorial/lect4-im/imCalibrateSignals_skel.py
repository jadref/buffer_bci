#!/usr/bin/env python3
# Set up imports and paths
import sys, os
# Get the helper functions for connecting to the buffer
try:     pydir=os.path.dirname(__file__)
except:  pydir=os.getcwd()    
sigProcPath = os.path.join(os.path.abspath(pydir),'../../python/signalProc')
sys.path.append(sigProcPath)
import bufhelp 

# connect to the buffer, if no-header wait until valid connection
bufhelp.connect()

trlen_ms = 600

print("Calibration phase")
# grab data after every t:'stimulus.target' event until we get a {t:'stimulus.training' v:'end'} event 
data, events, stopevents = bufhelp.gatherdata()
# save the calibration data
pickle.dump({"events":events,"data":data}, open("subject_data", "w"))
