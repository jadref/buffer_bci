#!/usr/bin/env python3
# Set up imports and paths
bufferpath = "../../dataAcq/buffer/python"
sigProcPath = "../signalProc"
import pygame, sys
from pygame.locals import *
from time import sleep, time
import os
import numpy
bufhelpPath = "../../python/signalProc"
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),bufhelpPath))
import bufhelp

def echoClient(timeout=5000):
        		
    ## init connection to the buffer
    ftc,hdr=bufhelp.connect();

    # Now do the echo client
    nEvents=hdr.nEvents;
    endExpt=None;
    while endExpt is None:
        bufhelp.sendEvent('echo',1)
        
        # wait for ackknowledgement from Server
        ack_received = False
        while ack_received is False:
            (curSamp,curEvents)=ftc.wait(-1,nEvents,timeout) # Block until there are new events to process
            if curEvents>nEvents :
                evts=ftc.getEvents([nEvents,curEvents-1]) 
                nEvents=curEvents # update record of which events we've seen
                for evt in evts:
                    if evt.type == "exit": endExpt=1
                    if evt.type == "ack": ack_received = True
                    print(evt)
            else:
                print("Waiting for acknowledgement...")
    
    ftc.disconnect() # disconnect from buffer when done


if __name__ == "__main__":
    echoClient();
