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
current_text = visual.TextStim(mywin, text='',color=(-1,-1,-1),wrapWidth = 800) 
break_text = visual.TextStim(mywin, text='Break \n\nPress any key to continue...',color=(-1,-1,-1),wrapWidth = 800) 
goodbye_text = visual.TextStim(mywin, text='Bye! \n\nPress a key to finish...',color=(-1,-1,-1),wrapWidth = 800) 

# ************** Start run sentences **************
showText(welcome_text)
bufhelp.sendEvent('experiment','start')
waitForKeypress()

for s in range(nr_sequences):
    bufhelp.sendEvent('sequence','start')
    for t in range(nr_trials):
        r = np.random.randint(0,len(stim))
        current_text.text = stim[r]
        showText(current_text)
        bufhelp.sendEvent('stimulus',stim[r])
        if r is 1:
           socket.socket(socket.AF_INET,socket.SOCK_DGRAM,0).sendto(bytes(1),('localhost',8300))
        core.wait(stimDuration) 
        mywin.flip()
        core.wait(interStimDuration) 
    bufhelp.sendEvent('sequence','end')
    mywin.flip()
    showText(break_text)
    bufhelp.sendEvent('break','start')
    waitForKeypress()
    bufhelp.sendEvent('break','end')
bufhelp.sendEvent('experiment','end')
bufhelp.sendEvent('sequence','end')

showText(goodbye_text)
bufhelp.sendEvent('experiment','end')
waitForKeypress()




