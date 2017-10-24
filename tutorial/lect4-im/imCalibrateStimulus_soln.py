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
txtColor=(1,1,1)

# make the target sequence
tgtSeq=list(range(nSymbs))*int(nSeq/nSymbs +1) # sequence in sequential order
shuffle(tgtSeq) # N.B. shuffle works in-place!

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
stimPos=[];
hdls=[];
stimRadius=.3;
theta=np.linspace(0,np.pi,nSymbs)
stimPos=np.stack((np.cos(theta),np.sin(theta))).T #[nSymbs x 2]
for hi,pos in enumerate(stimPos):  #N.B. enumerate goes over 1st dim if stimPos is array
    print('%d) stimPos=(%f,%f)'%(hi,pos[0],pos[1]))
    circ=patches.Circle(pos,stimRadius,facecolor=bgColor)
    hhi=ax.add_patch(circ)
    hdls.insert(hi,hhi)
# add symbol for the center of the screen
spos   =np.array((0,0))#.reshape((1,-1))
stimPos=np.vstack((stimPos,spos)) #[nSymbs+1 x 2]
circ   =patches.Circle((0,0),stimRadius/4,facecolor=bgColor)
hhi    =ax.add_patch(circ)
hdls.insert(nSymbs,hhi)
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
    
    sleep(intertrialDuration)

    # show the baseline
    hdls[-1].set(visible=True,facecolor=fixColor)
    drawnow()
    bufhelp.sendEvent('stimulus.baseline','start')
    sleep(baselineDuration)
    bufhelp.sendEvent('stimulus.baseline','end')
      
    #show the target
    print("%d) tgt=%d :"%(si,tgt))
    [_.set(facecolor=bgColor,visible=True) for _ in hdls]
    hdls[tgt].set(facecolor=tgtColor)
    drawnow()
    bufhelp.sendEvent('stimulus.target',tgt)
    bufhelp.sendEvent('stimulus.trial','start')
    sleep(trialDuration)
      
    # reset the display
    [ _.set(visible=False) for _ in hdls]
    txthdl.set(visible=False)
    drawnow()
    bufhelp.sendEvent('stimulus.trial','end');

bufhelp.sendEvent('stimulus.training','end')
txthdl.set(text=['Thanks for taking part!' '' 'Press key to finish'],visible=True)
drawnow()
waitforkey(fig)
