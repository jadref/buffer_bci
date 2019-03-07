#!/usr/bin/env python3
# Set up imports and paths
bufferpath = "../../dataAcq/buffer/python"
sigProcPath = "../signalProc"
from psychopy import visual, core, event, gui, sound, data, monitors
import numpy as np
import sys
import socket
from time import sleep, time
import os
bufhelpPath = "../../python/signalProc"
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),bufhelpPath))
import bufhelp
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),sigProcPath))

# init connection to the buffer
ftc,hdr=bufhelp.connect();

def showText(text):
    text.draw()
    mywin.flip()

def waitForKeypress():
    allKeys = event.getKeys()
    while len(allKeys)==0:
        allKeys = event.getKeys()
    if 'escape' in allKeys[0]:
        mywin.close() # quit
        core.quit()

# Setup the stimulus window
screenWidth = 600
screenHeight = 400 
mywin = visual.Window(size=(screenWidth, screenHeight), fullscr=False, screen=1, allowGUI=False, allowStencil=False,
    monitor='testMonitor', units="pix",color=[1,1,1], colorSpace='rgb',blendMode='avg', useFBO=True)

#define variables
stim = [' ', '+']
nr_sequences = 5
nr_trials = 10
interStimDuration= 0.8
stimDuration = 0.2

#create some stimuli
welcome_text = visual.TextStim(mywin, text='Welcome! \n\nPress a key to start...',color=(-1,-1,-1),wrapWidth = 800) 

# ************** Start run sentences **************
showText(welcome_text)

# label data
bufhelp.sendEvent('experiment','start')

waitForKeypress()

# inject an ERP into the trigger channel
socket.socket(socket.AF_INET,socket.SOCK_DGRAM,0).sendto(bytes(1),('localhost',8300))

# pause
core.wait(stimDuration) 

# refresh the screen
mywin.flip()
 




