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

#Set to True if the program has to run in fullscreen mode.
fullscreen = False #True

# make the target sequence
sentences=['hello world','this is new!','BCI is fun!'];
interSentenceDuration=3;
interCharDuration=1;

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


## HELPER FUNCTIONS
def updateFrame(string, big=False, center=True):
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

    # draw the window onto the screen
    pygame.display.update()

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
# set up the colors
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)

##--------------------- Start of the actual experiment loop ----------------------------------
updateFrame(["Welcome to the Oddball Music Experiment"])

sendEvent('stimulus.sentences','start');
## STARTING PROGRAM LOOP
for si,sentence in enumerate(sentences):
    
    # reset the display
    updateFrame('')
    sendEvent('stimulus.sentence',sentence)

    for ci,char in enumerate(sentence):
        sendEvent('stimulus.character',char)
        updateFrame(sentence[0:ci+1])
        sleep(interCharDuration)
    
    sleep(interSentenceDuration)
    
    #wait for key-press to continue
    updateFrame('Press key to continue')
    waitForKey()

sendEvent('stimulus.sentences','end')
updateFrame(['Thanks for taking part!' '' 'Press key to finish'])
waitForKey()
