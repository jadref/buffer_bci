#!/usr/bin/env python3
# Set up imports and paths
bufferpath = "../../dataAcq/buffer/python"
sigProcPath = "../signalProc"
import pygame, sys
from pygame.locals import *
from time import sleep, time
import os
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),bufferpath))
import FieldTrip
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),sigProcPath))

## CONFIGURABLE VARIABLES
# Connection options of fieldtrip, hostname and port of the computer running the fieldtrip buffer.
hostname='localhost'
port=1972

## init connection to the buffer
timeout=5000
ftc = FieldTrip.Client()
# Wait until the buffer connects correctly and returns a valid header
hdr = None;
while hdr is None :
    print(('Trying to connect to buffer on %s:%i ...'%(hostname,port)))
    try:
        ftc.connect(hostname, port)
        print('\nConnected - trying to read header...')
        hdr = ftc.getHeader()
    except IOError:
        pass

    if hdr is None:
        print('Invalid Header... waiting')
        sleep(1)
    else:
        print(hdr)
        print((hdr.labels))
fSample = hdr.fSample

#--------------------------------------------------------------
verb=0;
nSymbs=3;
nSeq=15;
nBlock=2;%10; % number of stim blocks to use
trialDuration=3;
baselineDuration=1;
intertrialDuration=2;

bgColor=(125, 125, 125);
tgtColor=(0, 255, 0);
fixColor=(255, 0, 0);


## HELPER FUNCTIONS
def drawString(string, big=False, center=True):
    """ Display the given string on the display """
    if type(string) is not list:
        string = [string]

    # draw the white background onto the surface
    windowSurface.fill((0,0,0))

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

def drawTrial(nSymb,tgtSeq=None):
    # draw the white background onto the surface
    windowSurface.fill((0,0,0))

    winRect=windowSurface.get_rect()

    t_radius = winRect.width *.1 # radius of the targets
    # draw each of the targets in turn with the right color
    for ti in range(0,nSymb):
        t_state = 0
        if not tgtSeq is None:
            t_state = tgtSeq(ti)
        t_theta=math.PI*ti/nSymbs
        t_center=(math.cos(t_theta) math.sin(t_theta))
        if t_state<=0 : t_color=bgcolor
        if t_state>0 : t_color=tgtcolor
        pygame.draw.circle(windowSurface,t_color,t_center,t_radius)
    # draw final fixation point
    pygame.draw.circle(windowSurface,bgcolor,winRect.center,winRect.width*.05)

def drawNow():
    # draw the window onto the screen
    
    
def waitForKey():
    """ Wait for the user to press a key and return the pressed key."""
    event = pygame.event.wait()
    while not (event.type == KEYDOWN): 
        event = pygame.event.wait()
    return event.key


# Buffer interfacing functions 
def sendEvent(event_type, event_value=1, sample=-1):
    e = FieldTrip.Event()
    e.type=event_type
    e.value=event_value 
    e.sample=sample
    ftc.putEvents(e)

# set  up pygame
pygame.init()
# set up the window
windowSurface = pygame.display.set_mode((640,480),  1, 32)
pygame.display.set_caption('Sentences Example')
# set up fonts
basicFont = pygame.font.SysFont(None, 48)
basicBigFont = pygame.font.SysFont(None, 48*2)

##--------------------- Start of the actual experiment loop ----------------------------------
drawString(["Welcome to the Oddball Music Experiment"])
pygame.display.update() # drawnow equivalent...

sendEvent('stimulus.training','start');
## STARTING PROGRAM LOOP
for si in range(0,nSeq):
    
    # reset the display
    drawString('')
    pygame.display.update() # drawnow equivalent...
    time.sleep(intertrialDuration)

    # reset with red fixation to alert to trial start
    drawStim(0)
    pygame.display.update()
    sendEvent('stimulus.baseline','start')
    time.sleep(baselineDuration)
    sendEvent('stimulus.baseline','end')

    # show the target cue
    drawTrial(nSymbs,tgtSeq[si])
    pygame.display.update()
    sendEvent('stimulus.target',[i for i,x in enumerate(tgtSeq[si]) if x])
    sendEvent('stimulus.trial','start')
    time.sleep(trialDuration)

    # reset the cue and fixation point to indicate trial end
    drawTrial(nSymbs)
    pygame.display.update()    
    sendEvent('stimulus.trial','end');

sendEvent('stimulus.training','end')
drawString(['Thanks for taking part!' '' 'Press key to finish'])
pygame.display.update()    
waitForKey()
