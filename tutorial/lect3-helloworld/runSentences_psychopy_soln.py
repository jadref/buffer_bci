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

#define variables
sentence = ['Hello World!', 'How are you today?', 'Good, thank you!']
interCharDuration=1
interSentenceDuration=5

#create some stimuli
welcome_text = visual.TextStim(mywin, text='Welcome! \n\nPress a key to start...',color=(-1,-1,-1),wrapWidth = 800) 
current_text = visual.TextStim(mywin, text='',color=(-1,-1,-1),wrapWidth = 800) 
goodbye_text = visual.TextStim(mywin, text='Bye! \n\nPress a key to finish...',color=(-1,-1,-1),wrapWidth = 800) 

# ************** Start run sentences **************
showText(welcome_text)
bufhelp.sendEvent('experiment','start')
waitForKeypress()

bufhelp.sendEvent('stimulus.seq','start')
for s in range(len(sentence)):
    current_sentence = sentence[s]
    bufhelp.sendEvent('stimulus.sentence','start')
    for i in range(len(current_sentence)):
        for c in range(i+1):
            current_text.text = current_text.text + current_sentence[c]
        showText(current_text)
        bufhelp.sendEvent('stimulus.letter',current_sentence[i])
        current_text.text = '';
        core.wait(interCharDuration) 
    bufhelp.sendEvent('stimulus.sentence','end')
    mywin.flip()
    core.wait(interSentenceDuration) 
bufhelp.sendEvent('stimulus.seq','end')

showText(goodbye_text)
bufhelp.sendEvent('experiment','end')
waitForKeypress()




