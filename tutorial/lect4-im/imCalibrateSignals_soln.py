#!/usr/bin/env python3
# Set up imports and paths
import sys, os
# Get the helper functions for connecting to the buffer
sigProcPath = "../signalProc"
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),sigProcPath))
import bufhelp 
import pickle
import h5py

# connect to the buffer, if no-header wait until valid connection
ftc,hdr=bufhelp.connect()

trlen_ms = 600
dname  ='training_data';
cname  ='clsfr';

print("Calibration phase")
# grab data after every t:'stimulus.target' event until we get a {t:'stimulus.training' v:'end'} event 
data, events, stopevents = bufhelp.gatherdata("stimulus.target",trlen_ms,("stimulus.training","end"), milliseconds=True)
# save the calibration data
pickle.dump({"events":events,"data":data,'hdr':hdr}, open(dname+".pk", "w"))
# also as a hdf5 / .mat v7.3 fi
f = h5py.File(dname+'.mat','w')
f.create_dataset('data',data=data)
f.create_dataset('events',data=events)
f.create_dataset('hdr',data=hdr)

