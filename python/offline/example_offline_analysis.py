#!/usr/bin/env python3
# Set up imports and paths
import sys, os
# add the buffer bits to the search path
try:     pydir=os.path.dirname(__file__)
except:  pydir=os.getcwd()    
sigProcPath = os.path.join(os.path.abspath(pydir),'../../python/signalProc')
sys.path.append(sigProcPath)
import bufhelp
bufferPath  = os.path.join(os.path.abspath(pydir),'../../dataAcq/buffer/python')
sys.path.append(bufferPath)
import FieldTrip

# directory where the data lives
dataDir='../../matlab/offline/example_data/raw_buffer/0001'

# read the header, events, and raw data
hdr   =FieldTrip.read_buffer_offline_header(os.path.join(dataDir,'header'))
events=FieldTrip.read_buffer_offline_events(os.path.join(dataDir,'events'))
data  =FieldTrip.read_buffer_offline_data(os.path.join(dataDir,'samples'),hdr)

# TODO: [] sliceraw into target-events and associated data
# TODO: [] train classifier on sliced data
