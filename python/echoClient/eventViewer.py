#!/usr/bin/env python
import sys
sys.path.append("../../dataAcq/buffer/python")
import numpy
import FieldTrip
import time

def pythonclient(hostname='localhost',port=1972,timeout=5000):
        		
    ftc = FieldTrip.Client()		
    # Wait until the buffer connects correctly and returns a valid header
    hdr = None;
    while hdr is None :
        print 'Trying to connect to buffer on %s:%i ...'%(hostname,port)
        try:
            ftc.connect(hostname, port)
            print '\nConnected - trying to read header...'
            hdr = ftc.getHeader()
	except IOError:
            pass
	
        if hdr is None:
            print 'Invalid Header... waiting'
            time.sleep(1)
        else:
            print hdr
            print hdr.labels

    # Now do the echo server
    nEvents=hdr.nEvents;
    endExpt=None;
    while endExpt is None :
        (curSamp,curEvents)=ftc.wait(-1,nEvents,timeout) # Block until there are new events to process
        if curEvents>nEvents :
            evts=ftc.getEvents([nEvents,curEvents-1]) 
            nEvents=curEvents # update record of which events we've seen
            for evt in evts:
                print evt
        else:
            print "Wait timeout, waiting"	
    ftc.disconnect()


if __name__ == "__main__":
    hostname='localhost'
    port=1972
    timeout=5000    
    if len(sys.argv)>1: # called with options, i.e. commandline
        hostname = sys.argv[1]
	if len(sys.argv)>2:
            try:
                port = int(sys.argv[2])
            except:
                print 'Error: second argument (%s) must be a valid (=integer) port number'%sys.argv[2]
                sys.exit(1)
    pythonclient(hostname,port);
