#!/usr/bin/env python3
# Set up imports and paths
bufferpath = "../../dataAcq/buffer/python"
sigProcPath = "../signalProc"
from psychopy import visual, core, event, gui, sound, data, monitors
import numpy as np
import sys
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

# wait for user keypress to
def waitForKeypress():
    allKeys = event.getKeys()
    while len(allKeys)==0:
        allKeys = event.getKeys()
    if 'escape' in allKeys[0]:
        mywin.close() # quit
        core.quit()

# Setup the stimulus window
screenWidth = 1300
screenHeight = 700 
mywin = visual.Window(size=(screenWidth, screenHeight), fullscr=False, screen=1, allowGUI=False, allowStencil=False,
    monitor='testMonitor', units="pix",color=[1,1,1], colorSpace='rgb',blendMode='avg', useFBO=True)

#create some stimuli
current_text = visual.TextStim(mywin, text='blah',color=(-1,-1,-1),wrapWidth = 800) 

# ************** Start run sentences **************

# show some text
showText(current_text)

# label data
bufhelp.sendEvent('experiment','start')

# pause (in secs)
core.wait(1) 





