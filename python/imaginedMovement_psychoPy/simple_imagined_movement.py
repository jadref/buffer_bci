#!/usr/bin/env python
# import necessary libraries from Psychopy and buffer_bci-master
from psychopy import visual, core, event, gui, sound, data, monitors
from random import shuffle
import numpy as np
import struct, sys, time, os

# use the buffer helper for seting up the connrection, sending/waiting for events
bufhelppath="../signalProc";
sys.path.append(os.path.dirname(__file__) + "/" + bufhelppath)
from bufhelp import *

# ************** Set up buffer connection **************
# set hostname and port of the computer running the fieldtrip buffer.
hostname='localhost'
port=1972
ftc,hdr=connect(hostname,port)

getFeedbackCounter = 0
current_block = 1

# ************** Define some handy functions for experiment **************

# Show instruction
def show_instr(instructionText):
    instruction = visual.TextStim(mywin, text=instructionText,color=(1,1,1),height = 25) 
    instruction.draw()
    mywin.flip()
    # wait for key-press
    allKeys = event.getKeys()
    while len(allKeys)==0:
        allKeys = event.getKeys()

# define break
def do_break():
    breaktext = visual.TextStim(mywin, text="Break\n\nPress <space> to continue...",color=(1,1,1),height = 50) 
    breaktext.draw()
    mywin.flip()
    # wait for key-press
    allKeys = event.getKeys()
    while len(allKeys)==0:
        allKeys = event.getKeys()

# define run through trials
def run_exp(nr_blocks,stimulus_conditions, stimulus_instructions,maxTime,feedback):
    current_trial = 1
    global getFeedbackCounter
    global current_block
    timer = core.Clock()
    for block in range (1,nr_blocks+1):
        instruction = visual.TextStim(mywin, text="Block "+str(current_block),color=(1,1,1),height = 50) 
        instruction.draw()
        mywin.flip()
        sendEvent("experiment.block",current_block)
        core.wait(2)
        for trial in range(1,len(stimulus_conditions)):
            instruction = visual.TextStim(mywin, text=stimulus_instructions[stimulus_conditions[trial-1]-1],color=(1,1,1),height = 50) 
            instruction.draw()
            mywin.flip()
            sendEvent("experiment.trial",stimulus_instructions[stimulus_conditions[trial-1]-1])
            core.wait(4)
            if feedback is True:
                feedbackEvt = buffer_newevents("feedback",1000)
                if feedbackEvt is None or len(feedbackEvt)==0:
                    feedbackTxt='None'
                else:
                    feedbackTxt=str(feedbackEvt[-1].value)
                getFeedbackCounter = getFeedbackCounter + 1
                visual.TextStim(mywin,text="Feedback = " + feedbackTxt,color=(1,1,1),height=50).draw()
                mywin.flip()
                sendEvent("experiment.feedback",feedbackTxt)
                core.wait(2)
                
            mywin.flip()
            core.wait(1)
        if block < nr_blocks:
            # break
            do_break()
        current_block += 1
        sendEvent("experiment.block",0)

# ************** Set up stimulus screen and set experiment parameters **************

#present a dialogue to provide the current participant code
ppcode = {'Participant':01}
dlg = gui.DlgFromDict(ppcode, title='Experiment', fixed=['01'])
if dlg.OK==False:
    core.quit() #the user hit cancel so exit

# Setup the stimulus window
mywin = visual.Window(size=(800, 600), fullscr=False, screen=0, allowGUI=False, allowStencil=False,
    monitor='testMonitor', units="pix",color=[0,0,0], colorSpace='rgb',blendMode='avg', useFBO=True)

#create some stimuli
instructions = "Simple Imagined Movement Experiment \n\nDuring the trails imagine yourself vigerously shaking the indicated body part (left hand, right hand, left foot or right foot).\n\nPress <space> to continue..." # instructions training phase
feedbackInstructions = "Feedback Phase\n\nPress <space> to continue..."# instructions feedback phase

# set conditions
stimulus_conditions = [1,2,3,4]
stimulus_instructions = ['Left Hand','Right Hand','Left Foot','Right Foot']
shuffle(stimulus_conditions)

# ************** Start experiment **************

# Show instruction start
show_instr(instructions)

# practice block
maxTime = 4
nr_blocks = 1
feedback = False
run_exp(nr_blocks,stimulus_conditions, stimulus_instructions,maxTime,feedback)

# Show instruction test
show_instr(feedbackInstructions)

# feedback block
shuffle(stimulus_conditions)
nr_blocks = 1
feedback = True
run_exp(nr_blocks,stimulus_conditions, stimulus_instructions,maxTime,feedback)

# ************** End of experiment **************
sendEvent("experiment.exit",1)
thankyou = visual.TextStim(mywin, text="End of the experiment.\n\nThank you for your participation!",color=(1,1,1),height = 25) 
thankyou.draw()
mywin.flip()
core.wait(2)

#cleanup
mywin.close()
ftc.disconnect()
core.quit()
sys.exit()
