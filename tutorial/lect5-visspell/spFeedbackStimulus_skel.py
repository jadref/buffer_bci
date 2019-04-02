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
    if fig is None : fig=plt.gcf()
    fig.canvas.draw()
    fig.canvas.flush_events()
    #plt.pause(1e-3) # wait for draw.. 1ms

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


def injectERP(amp=1,host="localhost",port=8300):
    """Inject an erp into a simulated data-stream, sliently ignore if failed, e.g. because not simulated"""
    import socket
    try:
        socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0).sendto(bytes([amp]),(host,port))
    except: # sliently igore any errors
        pass
        
## CONFIGURABLE VARIABLES
verb=0
symbols=['a', 'b', 'c', 'd']
nSymbs =sum([len(r) for r in symbols])
nSeq=6
nRep=5
cueDuration=2
postCueDuration=1
epochDuration=0.1
interEpochDuration=0.1
interSeqDuration=2

bgColor =(.5,.5,.5)
tgtColor=(0,1,0)
fbColor=(0,0,1)
fixColor=(1,0,0)
txtColor=(1,1,1)
flashColor=(1,1,1)

def initGrid(symbols,ax=None,txtColor=txtColor):
    "Initialize a grid of letters on the screen"
    if ax is None: # default to using the current axes
        ax=plt.gca()
    axw=ax.get_xlim()
    axh=ax.get_ylim()
    print('Symbs(%d)=[%s]'%(len(symbols),[str(s) for s in symbols]))
    w = (axw[1]-axw[0])/(len(symbols)+1)
    h = (axh[1]-axh[0])/(max([len(r) for r in symbols]))
    print('xlim=[%f,%f]/%d=%f ylim=[%f,%f]/%d=%f'%(axw[0],axw[1],len(symbols),w,axh[0],axh[1],0,h))
    hdls=[]
    for i,row in enumerate(symbols):
        x=axw[0]+i*w+w/2
        rowh=[]
        # TODO: ensure row is enumeratable...
        for j,symb in enumerate(row):
            y=axh[0]+j*h+h/2
            print('%s @(%f,%f)'%(symb,x,y))
            txthdl =ax.text(x, y, symb, color=txtColor,visible=True)
            rowh.append(txthdl)
        if len(rowh)==1: rowh=rowh[0] # BODGE: ensure hdls has same structure as symbols
        hdls.append(rowh)
    print('hds(%d)=[%s]'%(len(hdls),str(hdls)))
    drawnow()
    return hdls
            
##--------------------- Start of the actual experiment loop ----------------------------------

bufhelp.sendEvent('stimulus.feedback','start');
state = None

## STARTING stimulus loop

#catch the prediction
# N.B. use state to track which events processed so far
events,state = bufhelp.buffer_newevents('classifier.prediction',5000,state)
if events == []:
    print("Error! no predictions, continuing")
else:
    # get all true stimulus into 1 numpy array
    stimSeq = np.array(stimSeq) # [ nEpochs x nSymbs ]
    # get all predictions into 1 numpy array
    pred = np.array([e.value for e in events]) # [ nEpochs ]
    ss   = stimSeq[:len(pred),:] # [ nSymbs x nEpochs ]
    # similarity to prediction for each output [ nSymbs ]        
    sim  = np.dot(pred,ss.T)
    # max similarity is the predicted class
    predIdx= np.argmax(sim,0) # predicted class

bufhelp.sendEvent('stimulus.feedback','end')
txthdl.set(text='Thanks for taking part! Press key to finish',visible=True)
drawnow()
waitforkey(fig)
