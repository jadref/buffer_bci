#!/usr/bin/env python3
# Set up imports and paths
bufferpath = "../../dataAcq/buffer/python"
sigProcPath = "../signalProc"
from time import sleep, time
import os
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),bufferpath))
import numpy
import FieldTrip
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),sigProcPath))
import FieldTrip

def echoServer(hostname='localhost',port=1972,timeout=5000):
        		
    ftc = FieldTrip.Client()		
    # Wait until the buffer connects correctly and returns a valid header
    hdr = None;
    while hdr is None :
        print('Trying to connect to buffer on %s:%i ...'%(hostname,port))
        try:
            ftc.connect(hostname, port)
            print('\nConnected - trying to read header...')
            hdr = ftc.getHeader()
        except IOError:
            pass
	
        if hdr is None:
            print('Invalid Header... waiting')
            time.sleep(1)
        else:
            print(hdr)
            print(hdr.labels)

    # Now do the echo server
    nEvents=hdr.nEvents;
    endExpt=None;
    while endExpt is None :
        (curSamp,curEvents)=ftc.wait(-1,nEvents,timeout) # Block until there are new events to process
        if curEvents>nEvents : # get any new events
            evts=ftc.getEvents([nEvents,curEvents-1]) 
            nEvents=curEvents # update record of which events we've seen
            ftc.putEvents(evt)
    
    ftc.disconnect() # disconnect from buffer when done

if __name__ == "__main__":
    hostname='localhost'
    port=1972
    echoServer(hostname,port);
