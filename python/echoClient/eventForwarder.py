#!/usr/bin/env python3
bufferpath = "../../python/signalProc"
fieldtripPath="../../dataAcq/buffer/python"

import os, sys, random, math, time, socket, struct
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),bufferpath))
import bufhelp
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),fieldtripPath))
import FieldTrip

# Configuration of buffer
buffer1_hostname='localhost'
buffer1_port=1972

# Configuration of forwarding buffer
buffer2_hostname='localhost'
buffer2_port=1972
# holder for the buffer2 connection
ftc2=None
# flag to stop running when used from another function
running=True

def connectBuffers(buffer1_hostname,buffer1_port,buffer2_hostname,buffer2_port):
        if buffer1_hostname==buffer2_hostname and buffer1_port==buffer2_port :
                print("WARNING:: fowarding to the same port may result in infinite loops!!!!")
        
        #Connect to Buffer2 -- do this first so the global state is for ftc1
        (ftc2,hdr2) = bufhelp.connect(buffer2_hostname,buffer2_port)
        print("Connected to " + buffer2_hostname + ":" + str(buffer2_port))
        print(hdr2)

        #Connect to Buffer1
        (ftc1,hdr1) = bufhelp.connect(buffer1_hostname,buffer1_port)
        print("Connected to " + buffer1_hostname + ":" + str(buffer1_port))
        print(hdr1)
        return (ftc1,ftc2)

# Receive events from the buffer1 and send them to buffer2
def forwardBufferEvents(ftc1,ftc2):
        global running
        global ftc
        ftc=ftc1
        while ( running ):
                events = bufhelp.buffer_newevents()
                for evt in events:
                        print(str(evt.sample) + ": " + str(evt))
                        ftc2.putEvents(evt)

if __name__ == "__main__":
        if len(sys.argv)>1: # called with options, i.e. commandline
                buffer2_hostname = sys.argv[1]
        if len(sys.argv)>2:
            try:
                buffer2_port = int(sys.argv[2])
            except:
                print('Error: second argument (%s) must be a valid (=integer) port number'%sys.argv[2])
                sys.exit(1)
        (ftc1,ftc2)=connectBuffers(buffer1_hostname,buffer1_port,buffer2_hostname,buffer2_port)
        forwardBufferEvents(ftc1,ftc2)
