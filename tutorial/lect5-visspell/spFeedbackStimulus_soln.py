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

DEBUG=False #True # 

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



def initGrid(symbols,ax=None,txtColor=txtColor):
    "Initialize a grid of letters on the screen"
    if ax is None: # default to using the current axes
        ax=plt.gca()
    axw=ax.get_xlim()
    axh=ax.get_ylim()
    h = (axw[1]-axw[0])/(len(symbols)+1)
    w = (axh[1]-axh[0])/(max([len(r) for r in symbols]))
    hdls=[]
    for row,i in enumerate(symbols):
        y=i*h+h/2
        rowh=[]
        # TODO: ensure row is enumeratable...
        for symb,j in enumerate(row):
            x=j*w+w/2
            txthdl =ax.text(x, y, symb, color=txtColor)
            rowh.append(txthdl)
        if len(rowh)==1: rowh=rowh[0] # BODGE: ensure hdls has same structure as symbols
        hdls.append(rowh)
    return hdls

        
## CONFIGURABLE VARIABLES
verb=0
symbols=['a' 'b' 'c' 'd']
nSymbs =sum([len(r) for r in symbols])
nSeq=6
nRep=5
cueDuration=2
epochDuration=.1
interEpochDuration=.1;
interSeqDuration=2

bgColor =(.5,.5,.5)
tgtColor=(0,1,0)
fixColor=(1,0,0)
txtColor=(1,1,1)

# make the target sequence
tgtSeq=list(range(nSymbs)*int(nSeq/nSymbs +1) # sequence in sequential order
shuffle(tgtSeq) # N.B. shuffle works in-place!
tgtSeq=tgtSeq[1:nSeq]
            
##--------------------- Start of the actual experiment loop ----------------------------------
# set the display and the string for stimulus
if DEBUG:
    plt.switch_backend('agg') # N.B. command to work in non-display mode
fig = plt.figure(facecolor=(0,0,0))
    
fig.suptitle('RunSentences-Stimulus', fontsize=14, fontweight='bold',color=txtColor)
ax = fig.add_subplot(111) # default full-screen ax
ax.set_xlim((-1.5,1.5))
ax.set_ylim((-1.5,1.5))
ax.set_axis_off()
txthdl =ax.text(0, 0, 'This is some text', style='italic',color=txtColor)

# setup the targets
hdls=initGrid(symbols)
[ _.set(visible=False) for _ in hdls] # make all invisible

## init connection to the buffer
ftc,hdr=bufhelp.connect();

#wait for key-press to continue
[_.set(facecolor=bgColor) for _ in hdls]
txthdl.set(text='Press key to start')
drawnow()
waitforkey(fig)
txthdl.set(visible=False)

bufhelp.sendEvent('stimulus.training','start');
## STARTING stimulus loop
for si,tgt in enumerate(tgtSeq):
    
    sleep(interSeqDuration)
      
    # start the scanning loop
    for rep in range(nRep): 
        for si in range(nSymbs):
            # flash
            hdls[si].set(color=flashColor)
            drawnow()
            bufhelp.sendEvent('stimulus.cue',si)
            bufhelp.sendEvent('stimulus.tgtFlash',si==tgt)
            sleep(stimDuration)                
            # reset
            hdls[si].set(color=bgColor)
            drawnow()
            sleep(stimDuration)

    bufhelp.sendEvent('stimulus.trial','end');

    #catch the prediction
    # N.B. use state to track which events processed so far
    events,state = bufhelp.buffer_newevents('classifier.prediction',1500,state)
    if events is None:
        print("Error! no predictions, continuing")
    else:
        # get all predictions into 1 numpy array
        pred = np.array([e.value for e in events])
        nPred= len(pred)
        ss   = stimSeq[:,:nFlash]
        corr = np.dot(ss,pred)        
        predIdx= np.argmax(corr,0) # predicted class
            
    #show the feedback
    print("%d) pred=%d :"%(si,predIdx))
    hdls[predIdx].set(color=fbColor)
    drawnow()
    sleep(feedbackDuration)
      
    # reset the display
    [ _.set(color=bgColor) for _ in hdls]
    drawnow()

            
bufhelp.sendEvent('stimulus.training','end')
txthdl.set(text=['Thanks for taking part!' '' 'Press key to finish'],visible=True)
drawnow()
waitforkey(fig)
