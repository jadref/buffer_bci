#!/usr/bin/env python
# import necessary libraries from Psychopy and buffer_bci-master
from psychopy import visual, core, event, gui, sound, data, monitors
from random import shuffle
import numpy as np
import struct, sys, time
sys.path.append("../../dataAcq/buffer/python")
import FieldTrip

# ************** Set up buffer connection **************
# set hostname and port of the computer running the fieldtrip buffer.
hostname='localhost'
port=1972

# function to send events to data buffer
# use as: sendEvent("markername", markernumber, offset)
def sendEvent(event_type, event_value, offset=0):
    e = FieldTrip.Event()
    e.type = event_type
    e.value = event_value
    if offset>0 : 
        sample, bla = ftc.poll()
        e.sample = sample + offset + 1
    ftc.putEvents(e)

def buffer_newevents(evttype=None,timeout_ms=500,verbose=False):
    '''
    Wait for and return any new events recieved from the buffer between
    calls to this function
    
    timeout    = maximum time to wait in milliseconds before returning
    '''
    global ftc,nEvents # use to store number events processed accross function calls
    if not 'nEvents' in globals(): # first time initialize to events up to now
    	start, nEvents = ftc.poll()

    if verbose:
        print("Waiting for event(s) " + str(evtypes) + " with timeout_ms " + str(timeout_ms))

    start = time.time()
    elapsed_ms = 0
    events=[]
    while len(events)==0 and elapsed_ms<timeout_ms:
        nSamples,curEvents=ftc.wait(-1,nEvents, int(timeout_ms - elapsed_ms))
        if curEvents>nEvents:
			if nEvents<curEvents-50:
				print("Warning: long delay means missed events")
				nEvents = curEvents-50
            events = ftc.getEvents([nEvents,curEvents-1])            
            if not evttype is None and not events is None:
                events = filter(lambda x: x.type in evttype, events)
        nEvents = curEvents # update starting number events (allow for buffer restarts)
        elapsed_ms = (time.time() - start)*1000        
    return events

procnEvents=-1
def waitnewevents(evtypes, timeout_ms=1000,verbose = True):      
    """Function that blocks until a certain type of event is recieved. 
    evttypes is a list of event type strings, recieving any of these event types termintes the block.  
    All such matching events are returned
    """    
    global ftc, nEvents, nSamples, procnEvents
    start = time.time()
    update()
    if procnEvents<=0:
       procnEvents=nEvents
    elapsed_ms = 0
    
    if verbose:
        print "Waiting for event(s) " + str(evtypes) + " with timeout_ms " + str(timeout_ms)
    
    evt=None
    while elapsed_ms < timeout_ms and evt is None:
        nSamples, nEvents2 = ftc.wait(-1,procnEvents, timeout_ms - elapsed_ms)     

        if nEvents2 > procnEvents : # new events to process
            if procnEvents<nEvents2-50:
                print("Warning: long delay means missed events")
                procnEvents = nEvents2-50
            evts = ftc.getEvents((procnEvents, nEvents2 -1))
            evts = filter(lambda x: x.type in evtypes, evts)
            if len(evts) > 0 :
                evt=evts
        
        elapsed_ms = (time.time() - start)*1000
        procnEvents=nEvents2
        nEvents = nEvents2            
    return evt

#Connecting to Buffer
timeout=5000
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
        core.wait(1)
    else:
        print hdr
        print hdr.labels

fSample = hdr.fSample

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
                feedbackEvt = waitnewevents("feedback",1000)
                if feedbackEvt is None:
                    feedbackTxt='None'
                else:
                    feedbackTxt=str(feedbackEvt.value)
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
mywin = visual.Window(size=(1920, 1080), fullscr=True, screen=0, allowGUI=False, allowStencil=False,
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
