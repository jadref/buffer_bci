#!/usr/bin/env python3
# Set up imports and paths
import pygame, sys, os
from pygame.locals import *
# Get the helper functions for connecting to the buffer
try:     pydir=os.path.dirname(__file__)
except:  pydir=os.getcwd()    
sys.path.append(os.path.join(os.path.abspath(pydir),'../../python/signalProc'))
import bufhelp 

import math
import random

# connect to the buffer, if no-header wait until valid connection
bufhelp.connect()

## CONFIGURABLE VARIABLES
#--------------------------------------------------------------
verb=0;
nSymbs=3;
nSeq=15;
trialDuration=3;
baselineDuration=1;
intertrialDuration=2;
feedbackDuration=2;

bgColor=(125, 125, 125) # grey=background
tgtColor=(0, 255, 0) # gree=cue
fixColor=(255, 0, 0) # red=fix
fbColor=(0,0,255) # blue=feedback
WHITE=(255,255,255)
BLACK=(0,0,0)

## HELPER FUNCTIONS
def drawString(string, big=False, center=True):
    """ Display the given string on the display """
    if type(string) is not list:
        string = [string]

    # draw the white background onto the surface
    windowSurface.fill(BLACK)

    # render the text into a back-buffer
    if big:
        text = [basicBigFont.render(x, True, WHITE, BLACK) for x in string]
    else:
        text = [basicFont.render(x, True, WHITE, BLACK) for x in string]
    # get the size to position centrally on the screen
    rects = [x.get_rect() for x in text]
    h = sum([x.h for x in rects]) - rects[0].h
    offset = h/2

    # move the text to the center and draw onto the screen
    for t in text:
        textRect = t.get_rect()
        if center: textRect.centerx = windowSurface.get_rect().centerx

        textRect.centery = windowSurface.get_rect().centery - offset
        offset -= textRect.h

        # draw the text onto the surface
        windowSurface.blit(t, textRect)
    
def drawTrial(t_center,tgtSeq=None):
    # convert from tgt# to stim-seq
    if not tgtSeq is None and len(t_center)>1 and type(tgtSeq) is not list:
        tgtId=tgtSeq;
        tgtSeq=[0]*len(t_center)
        tgtSeq[tgtId]=1
    
    # draw the white background onto the surface
    windowSurface.fill((0,0,0))
    winRect=windowSurface.get_rect()

    # draw each of the targets in turn with the right color
    for ti in range(0,len(t_center)-1):
        t_theta=2*math.pi*ti/(nSymbs+1)
        t_center=(int(math.cos(t_theta)*winRect.width*.3)+winRect.centerx,
                  -int(math.sin(t_theta)*winRect.height*.3)+winRect.centery)
        t_state = 0
        if not tgtSeq is None:
            t_state = tgtSeq[ti]
        if t_state<=0 : t_color=bgColor
        if t_state==1 : t_color=tgtColor
        if t_state==2 : t_color=fbColor
        pygame.draw.circle(windowSurface,t_color,t_center[ti],int(t_radius))
    # draw final fixation point
    pygame.draw.circle(windowSurface,bgColor,t_center[nSymbs],int(winRect.width*.05))
    
def waitForKey():
    """ Wait for the user to press a key and return the pressed key."""
    event = pygame.event.wait()
    while not (event.type == KEYDOWN): 
        event = pygame.event.wait()
    return event.key

# set  up pygame
pygame.init()
# set up the window
windowSurface = pygame.display.set_mode((640,480),  1, 32)
pygame.display.set_caption('Sentences Example')
# set up fonts
basicFont = pygame.font.SysFont(None, 48)
basicBigFont = pygame.font.SysFont(None, 48*2)

# pre-compute the position of each target
t_radius = int(winRect.width *.07) # radius of the targets
for ti in range(0,nSymbs):
    t_theta=2*math.pi*ti/(nSymbs+1)
    t_center[ti]=(int(math.cos(t_theta)*winRect.width*.3)+winRect.centerx,
                  -int(math.sin(t_theta)*winRect.height*.3)+winRect.centery)
t_center[nSymbs]=winRect.center # fixation point

##--------------------- Start of the actual experiment loop ----------------------------------
drawString(["Motor Imagery Experiment" "Feedback phase" "" "Perform the Green cued task" "after trial feedback given in blue" "" "Key to continue"])
pygame.display.update() # drawnow equivalent...
waitForKey()

# make the target sequence
tgtSeq = range(0,nSymbs)*nSeq
random.shuffle(tgtSeq)

bufhelp.sendEvent('stimulus.testing','start')
events,state = buffer_newevents(timeout_ms=0) # initialize event queue
## STARTING STIMULUS LOOP
for si in range(0,nSeq):
    
    # reset the display
    drawString('')
    pygame.display.update() # drawnow equivalent...
    time.sleep(intertrialDuration)

    # reset with red fixation to alert to trial start
    drawTrial([t_center[-1]])
    pygame.display.update()
    bufhelp.sendEvent('stimulus.baseline','start')
    time.sleep(baselineDuration)
    bufhelp.sendEvent('stimulus.baseline','end')

    # show the target cue
    drawTrial(t_center,tgtSeq[si])
    pygame.display.update()
    bufhelp.sendEvent('stimulus.target',tgtSeq[si])
    bufhelp.sendEvent('stimulus.trial','start')
    time.sleep(trialDuration)

    # wait for predictions
    # N.B. use state to track which events processed so far
    events,state = bufhelp.buffer_newevents('classifier.prediction',1500,state)
    if events is None:
        print("Error! no predictions, continuing")
    else:
        if len(events)>1 :
            print("Warning: multiple predictions. Some ignored.");
        evt=events[-1] # only use the last event
        dv =evt.value
        if isinstance(dv,(int,long,float)):#binary problem, covert to per-class
            dv=[dv -dv]
        # convert to probability, using soft-max
        prob = math.exp([x - max(dv) for x in dv])
        prob = [x / sum(prob) for x in prob]

    # compute the position of the fixation point, weighted ave of rest
    fixPos= ( sum([x(1)*w for x,y in zip(t_center,prob)]),
              sum([x(2)*w for x,y in zip(t_center,prob)]) )
    predIdx = list.index(max(prob)) # predicted class
    drawTrial([t_center[0:-2] fixPos],predIdx) # update display
    pygame.display.update()    
    bufhelp.sendEvent('stimulus.predTgt',predIdx)
    time.sleep(feedbackDuration)

    # reset the cue and fixation point to indicate trial end
    drawTrial(t_center)
    pygame.display.update()    
    bufhelp.sendEvent('stimulus.trial','end');

bufhelp.sendEvent('stimulus.testing','end')
drawString(['Thanks for taking part!' '' 'Press key to finish'])
pygame.display.update()    
waitForKey()
quit()
