#!/usr/bin/python
## CONFIGURABLE VARIABLES
# Path of the folder containing the buffer client
bufferpath = "../../dataAcq/buffer/python"
# Connection options of fieldtrip, hostname and port of the computer running the fieldtrip buffer.
hostname='localhost'
port=1972

#Set to True if the program has to run in fullscreen mode.
fullscreen = False #True

#The default number of epochs.
number_of_epochs = 27

#The number of stimuli to play.
number_of_stimuli = 6

#The number of times to repeat each stimulus in a training sequence
number_of_repeats = 3

#The maximum number of lowered stimuli in a training sequence
max_lowered = 3

# set to true for keyboard control of the experimental progression
keyboard = True

## END OF CONFIGURABLE VARIABLES

import pygame, sys
from random import shuffle, randint
from time import sleep
from pygame.locals import *
from pyaudio import PyAudio
import wave
sys.path.append(bufferpath)
import FieldTrip
from math import ceil

## HELPER FUNCTIONS


def updateframe(string, big=False):
    if type(string) is not list:
        string = [string]

    # draw the white background onto the surface
    windowSurface.fill(BLACK)

    # render the text into a back-buffer
    if big:
        text = map(lambda x: basicBigFont.render(x, True, WHITE, BLACK), string)
    else:
        text = map(lambda x: basicFont.render(x, True, WHITE, BLACK), string)
    # get the size to position centrally on the screen
    rects = map(lambda x: x.get_rect(), text)
    h = sum(map(lambda x: x.h, rects)) - rects[0].h
    offset = h/2

    # move the text to the center and draw onto the screen
    for t in text:
        textRect = t.get_rect()
        textRect.centerx = windowSurface.get_rect().centerx

        textRect.centery = windowSurface.get_rect().centery - offset
        offset -= textRect.h

        # draw the text onto the surface
        windowSurface.blit(t, textRect)

    # draw the window onto the screen
    pygame.display.update()


def close():
    pygame.quit()
    sys.exit()
    stream.stop_stream()
    stream.close()
    p.terminate()

def playStimulus(i):
    offset = stream.get_output_latency()*fSample
    sendEvent("stimulus.play", str(i), offset)
    stream.write(data[i])
    
def playSingleStimulus(i):
    offset = stream.get_output_latency()*fSample
    sendEvent("stimulus.online.play", str(i), offset)
    stream.write(data[i])
    sleep(0.5);
    sendEvent("stimulus.online", "end", 0)

def runTrainingEpoch(nEpoch, nRep=3, maxLowered=3):
    dobreak(2, ["Training Epoch " + str(nEpoch), "starts in"])
    updateframe("+", True)

    ## Set up training sequence
    set_sequence = range(0,number_of_stimuli)
    shuffle(set_sequence)
    ## number of the stimuli which have reduced volume (for the user task)
    nr_lowered = randint(0,maxLowered)
    ## quiet stimuli are in same order after the loud stimuli
    low_sequence = [True]*nr_lowered + [False]*(number_of_stimuli - nr_lowered)
    shuffle(low_sequence)
    
    stimulus_sequence = list()

    for i in range(0,len(set_sequence)):
        for j in range(0,nRep): newSet.append(set_sequence[i]) # duplicate the stimulus nRep times
    	if low_sequence[i]:
    		newSet[0] = newSet[0] + nrStimuli
    		shuffle(newSet)
    	stimulus_sequence += newSet
    
    sendEvent("stimulus.feedback", "epoch" + str(nEpoch) + "nr" + str(nr_lowered) + "truth",0)

    for i in stimulus_sequence:
        playStimulus(i)

    sleep(0.2)
    getFeedback(nEpoch)

def getFeedback(nEpoch):
	updateframe(["How many lowered volume fragments?", "0-" + str(number_of_stimuli)], False)
	key = waitForKey()
	while not key in numKeyDict:
		key = waitForKey()
	sendEvent("stimulus.feedback", "epoch" + str(nEpoch) + "nr" + str(numKeyDict[key]), 0)
    
def dobreak(n, message):
    while n > 0:
        updateframe(message + [str(n)])
        sleep(0.1)
        n -= 0.1

def showInstructions():
  instructions = ["The training phase of the experiment will last about " + str(number_of_epochs) + " minutes.",
                  "About once every minute there will be a short break.",
                  "During training please focus on the spot on the screen",
                  "and try not to blink.","Press key to continue."]

  updateframe(instructions)
  waitForKey()

def showKeyboardInstructions():
	instructions=["Press:", " i - show expt instructions"," t - run training loop"," c - close", " 1..7 - play stimulus 1..7"]
	updateframe(instructions)


def doTraining():
  for i in range(1,(number_of_epochs+1)):
      runTrainingEpoch(i,number_of_repeats,max_lowered)
      if (i == ceil(number_of_epochs/2)):
          updateframe(["Long Break","Press space to continue"])
          waitForSpaceKey()
      elif i!= number_of_epochs:
          dobreak(3,["Break", "(Blink eyes)"])

  updateframe("Training Finished")
  sleep(2)
  sendEvent('stimulus.training','end')
  
def waitForSpaceKey():
  event = pygame.event.wait()
  while not (event.type == KEYDOWN and event.key == K_SPACE): 
    event = pygame.event.wait()
    
    
def waitForKey():
  event = pygame.event.wait()
  while not (event.type == KEYDOWN): 
    event = pygame.event.wait()
  return event.key

# Buffer interfacing functions 
def sendEvent(event_type, event_value, offset=0):
    e = FieldTrip.Event()
    e.type = event_type
    e.value = event_value
    if offset > 0:
        sample, bla = ftc.poll() #TODO: replace this with a clock-sync based version
        e.sample = sample + offset + 1
    ftc.putEvents(e)

def buffer_newevents(event_type, timeout):
    '''
    Wait for and return any new events matching event_type recieved from the buffer between
    calls to this function
    
    event_type = type of new events to match and return
    timeout    = maximum time to wait in milliseconds before returning
    '''
    start, nEvents = ftc.poll()
    events = []  # list of new events matching event_type

    stop = False
    timetogo=timeout
    while not stop and timetogo>0:
        nSamples,curEvents=ftc.wait(-1,nEvents, timetogo)
        if curEvents>nEvents:
            newevents = ftc.getEvents([nEvents curEvents])
            for evt in newevents:
                if evt.type == event_type:
                    stop = True
                    events.append(evt)
                    break
            nEvents = curEvents
    return events

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
        sleep(1)
    else:
        print hdr
        print hdr.labels
  
fSample = hdr.fSample

# set  up pygame and PyAudio
pygame.mixer.pre_init(44100, -16, 1, 128) # set audio to 1 channel and minimual buffer = fast startup
pygame.init()
p = PyAudio()

# set up the window
if fullscreen:
  windowSurface = pygame.display.set_mode(pygame.display.list_modes()[0], pygame.FULLSCREEN, 32)
else:
  windowSurface = pygame.display.set_mode((640,480),  1, 32)
  
pygame.display.set_caption('BCI Music Experiment')

## LOADING GLOBAL VARIABLES

# Loading Music data
nrStimuli = 7;

wf = map(lambda x: wave.open("stimuli/BR7_" + str(x) + ".wav" , 'rb'), range(1,nrStimuli+1))
wf += map(lambda x: wave.open("stimuli/BR7_" + str(x) + "_lowered.wav" , 'rb'), range(1,nrStimuli+1))
data = map(lambda x: x.readframes(x.getnframes()),wf)

names = ["Nutcracker Suite: March (Tchaikovsky)",
         "Galvanize",
         "Daft Punk is Playing at my House",
         "Agua de Beber",
         "Release the Pressure",
         "How Insensitive",
         "Erkilet Guzeli"]

# Opening Audio Stream

stream = p.open(format=p.get_format_from_width(wf[0].getsampwidth()),
            channels=wf[0].getnchannels(),
            rate=wf[0].getframerate(),
            output=True)

# set up the colors
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)

# set up fonts
basicFont = pygame.font.SysFont(None, 48)
basicBigFont = pygame.font.SysFont(None, 48*2)
updateframe(["Welcome to the BCI Music Experiment"])

#

numKeyDict = {K_0 : 0, K_1 : 1, K_2 : 2, K_3 : 3, K_4 : 4, K_5 : 5, K_6 : 6, K_7 : 7, K_8 : 8, K_9 : 9, K_KP0 : 0, K_KP1 : 1, K_KP2 : 2, K_KP3 : 3, K_KP4 : 4, K_KP5 : 5, K_KP6 : 6, K_KP7 : 7, K_KP8 : 8, K_KP9 : 9 } 

actions = dict()

actions["showinstructions"] = showInstructions
actions["starttraining"] =  doTraining
actions["close"] = close
actions["stimulus"] = lambda x: playStimulus(x)

actions_key = dict()

actions_key[K_i] = showInstructions
actions_key[K_t] = doTraining
actions_key[K_c] = close
actions_key[K_s] = lambda: playStimulus(0)
actions_key[K_1] = lambda: playStimulus(0)
actions_key[K_2] = lambda: playStimulus(1)
actions_key[K_3] = lambda: playStimulus(2)
actions_key[K_4] = lambda: playStimulus(3)
actions_key[K_5] = lambda: playStimulus(4)
actions_key[K_6] = lambda: playStimulus(5)
actions_key[K_7] = lambda: playStimulus(6)

## STARTING PROGRAM LOOP

if not keyboard:
	showInstructions()
	waitForKey()
	doTraining()
	close()
else:
	while True:
		showKeyboardInstructions()
	   	key = waitForKey()
	   	if key in actions_key:
			actions_key[key]()
