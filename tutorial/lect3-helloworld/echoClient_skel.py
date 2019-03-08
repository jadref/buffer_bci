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

    # send event to buffer
    bufhelp.sendEvent('echo',1)
        
    # wait for ackknowledgement from Server
       
    ftc.disconnect() # disconnect from buffer when done

if __name__ == "__main__":
    echoClient();
