#!/usr/bin/env python3
# Set up imports and paths
import sys, os
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import numpy as np
from time import sleep, time
from random import shuffle

# add the buffer bits to the search path
try:     pydir=os.path.dirname(__file__)
except:  pydir=os.getcwd()    
sigProcPath = os.path.join(os.path.abspath(pydir),'../../python/signalProc')
sys.path.append(sigProcPath)
import bufhelp

DEBUG=True # False #

## HELPER FUNCTIONS
def drawnow(fig=None):
    "force a matplotlib figure to redraw itself, inside a compute loop"
    if fig is None: fig=plt.gcf()
    fig.canvas.draw()
    plt.pause(1e-3) # wait for draw.. 1ms

currentKey=None
def keypressFn(event):
    "wait for keypress in a matplotlib figure, and store in the currentKey global"
    global currentKey
    currentKey=event.key
def waitforkey(fig=None,reset=True,debug=DEBUG):
    "wait for a key to be pressed in the given figure"
    if debug: return
    if fig is None: fig=gcf()
    global currentKey
    fig.canvas.mpl_connect('key_press_event',keypressFn)
    if reset: currentKey=None
    while currentKey is None:
        plt.pause(1e-2) # allow gui event processing

## CONFIGURABLE VARIABLES
verb=0
nSymbs=3
nSeq=15
nBlock=2 #10; # number of stim blocks to use
trialDuration=3
baselineDuration=1
intertrialDuration=2

bgColor =(.5,.5,.5)
tgtColor=(0,1,0)
fixColor=(1,0,0)

# make the target sequence
tgtSeq=list(range(nSymbs))*int(nSeq/nSymbs +1) # sequence in sequential order
shuffle(tgtSeq) # N.B. shuffle works in-place!

##--------------------- Start of the actual experiment loop ----------------------------------
# set the display and the string for stimulus
if DEBUG:
    plt.switch_backend('agg') # N.B. command to work in non-display mode
fig = plt.figure()
    
fig.suptitle('RunSentences-Stimulus', fontsize=14, fontweight='bold')
ax = fig.add_subplot(111) # default full-screen ax
ax.set_xlim((-1,1))
ax.set_ylim((-1,1))
ax.set_axis_off()
txthdl =ax.text(0, 0, 'This is some text', style='italic')

# setup the targets
stimPos=[];
hdls=[];
stimRadius=.5;
theta=np.linspace(0,np.pi,nSymbs)
stimPos=np.stack((np.cos(theta),np.sin(theta))) #[2 x nSymbs]
for hi,pos in enumerate(stimPos):
    rect=patches.Rectangle((pos[0]-stimRadius/2,pos[1]-stimRadius/2),stimRadius/2,stimRadius/2,facecolor=bgColor)
    hhi=ax.add_patch(rect)
    hdls.insert(hi,hhi)
# add symbol for the center of the screen
spos = np.array((0,0)).reshape((-1,1))
stimPos=np.hstack((stimPos,spos)) #[2 x nSymbs+1]
rect = patches.Rectangle((0-stimRadius/4,0-stimRadius/4),stimRadius/2,stimRadius/2,facecolor=bgColor)
hhi  =ax.add_patch(rect)
hdls.insert(nSymbs,hhi)
[ _.set(visible=False) for _ in hdls] # make all invisible


## init connection to the buffer
ftc,hdr=bufhelp.connect();

#wait for key-press to continue
[_.set(facecolor=bgColor) for _ in hdls]
txthdl.set(text='Press key to start')
drawnow()
waitforkey(fig)

bufhelp.sendEvent('stimulus.training','start')
state=None
## STARTING stimulus loop
for si,tgt in enumerate(tgtSeq):
    
    sleep(intertrialDuration)

    # show the baseline
    hdls[-1].set(visible=True,facecolor=fixColor)
    drawnow()
    bufhelp.sendEvent('stimulus.baseline','start')
    sleep(baselineDuration)
    bufhelp.sendEvent('stimulus.baseline','end')
      
    #show the target
    print("%d) tgt=%d :"%(si,tgt))
    [_.set(facecolor=bgColor) for _ in hdls]
    hdls[tgt].set(facecolor=tgtColor)
    drawnow()
    bufhelp.sendEvent('stimulus.target',tgt)
    bufhelp.sendEvent('stimulus.trial','start')
    sleep(trialDuration)

    #catch the prediction
    # N.B. use state to track which events processed so far
    events,state = bufhelp.buffer_newevents('classifier.prediction',1500,state)
    if events is None:
        print("Error! no predictions, continuing")
    else:
        if len(events)>1:
            print("Warning: multiple predictions. Some ignored.") 
        evt=events[-1] # only use the last event
        if isinstance(dv,(int,long,float)):#binary problem, covert to per-class
            dv = np.array((evt.value,-evt.value))
        else:
            dv =np.array(evt.value) # extract decision values
        # convert to probability, using soft-max
        prob = np.exp(dv - np.max(dv))
        prob = prop / np.sum(prob)

    predIdx= np.argmax(prob,0) # predicted class

    # give user feedback on the prediction
    # compute the position of the fixation point, weighted ave of rest
    fixPos = np.dot(prob,stimPos)    
    hdls[-1].set_xy(fixPos) # move the 
    hdls[-1].set(color=fbColor)
    hdls[predIdx].set(color=fbColor) # predicted target indication
    drawnow()
    
    bufhelp.sendEvent('stimulus.predTgt',predIdx)
    sleep(feedbackDuration)
        
    # reset the display
    hdls[-1].set_xy(stimPos[-1,:])
    [ _.set(visible=False) for _ in hdls]
    txthdl.set(visible=False)
    drawnow()
    bufhelp.sendEvent('stimulus.trial','end');

bufhelp.sendEvent('stimulus.training','end')
txthdl.set(text=['Thanks for taking part!' '' 'Press key to finish'])
waitforkey(fig)
