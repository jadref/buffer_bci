#!/usr/bin/python
## CONFIGURABLE VARIABLES
# Path of the folder containing the buffer client
bufferpath = "../../dataAcq/buffer/python"
sigProcPath = "../signalProc"

# Connection options of fieldtrip, hostname and port of the computer running the fieldtrip buffer.
hostname='localhost'
port=1972

#Set to True if the program has to run in fullscreen mode.
fullscreen = False #True

#The default number of epochs.
number_of_epochs = 7

#The number of stimuli to play.
number_of_stimuli = 6

#The number of times to repeat each stimulus in a training sequence
number_of_repeats = 3

# set to true for keyboard control of the experimental progression
keyboard = True

sequence_duration         = 15
inter_stimulus_interval   = .3
target_to_target_interval = 1
baseline_duration         = 3
sequences_for_break       = 3


## END OF CONFIGURABLE VARIABLES
import pygame, sys
from random import shuffle, randint
from time import sleep, time
from pygame.locals import *
import os
sys.path.append(bufferpath)
import FieldTrip
sys.path.append(sigProcPath)
import stimseq

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
    
def playSingleStimulus(i):
    sendEvent("stimulus.online.play", names[i])
    stimulusChan.play(sounds[i])
    # wait for the audio to finish
    while stimulusChan.get_busy()>0 : 
        sleep(0.1);
    sendEvent("stimulus.online", "end", 0)

def runTrainingEpoch(nEpoch,seqDur,isi,tti,distID,tgtID):
    dobreak(baseline_duration, ["Get Ready"]+["Training Epoch " + str(nEpoch)])
    updateframe("+", True)

    ## Set up training sequence
    ss = stimseq.StimSeq.mkStimSeqOddball(1,seqDur,isi,tti)
    
    ## get num targets
    nTgt=0; 
    for s in ss.stimSeq: nTgt+= 1 if s[0]==1 else 0

    # play the stimulus sequence
    sendEvent("stimulus.trial", "start")
    sendEvent("stimulus.numTargets", nTgt)
    
    t0=time()
    for ei in range(0,len(ss.stimTime_ms)):
        st  = ss.stimTime_ms[ei]
        ssi = ss.stimSeq[ei]
        tgt = ssi[0]==1
        audioID = tgtID if tgt else distID

        #print(str(time()-t0) + ") tn= " + str(st/1000) + " ttg=" + str((t0+st/1000)-time()))
        sleep((t0+st/1000)-time()) # sleep until we should play this sound
        # send events as close in time as possible to when the actual stimulus starts
        sendEvent("stimulus.target", tgt)   # target/non-target
        sendEvent("stimulus.play", names[audioID]) # which stimulus
        stimulusChan.play(sounds[audioID])

    # get user count of targets
    sleep(0.5)
    getFeedback(int(len(ss.stimTime_ms)/2),nTgt)
    sendEvent("stimulus.trail","end")

def getFeedback(maxLowered,trueLowered):
    updateframe(["How many lowered volume fragments?", "0-" + str(maxLowered)], False)
    key=[None]*2
    for i in range(2):
       key[i] = waitForKey()
       while not key[i] in numKeyDict:
            key[i] = waitForKey()
    respLowered=int(str(numKeyDict[key[0]]))*10 + int(str(numKeyDict[key[1]]))
    sendEvent("response.numTargets", respLowered)
    fbStr = [];
    if respLowered == trueLowered: fbStr += ["Correct!"]
    else:                          fbStr += ["Wrong!"]
    updateframe(fbStr + ["Response = " + str(respLowered)] 
                + ["True lowered fragments = " + str(trueLowered)])
    sleep(1)
    
def dobreak(n, message):
    while n > 0:
        updateframe(message + [" "] + [str(n)])
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
      # run with given parameters, and max audio difference
      runTrainingEpoch(i,sequence_duration,inter_stimulus_interval,target_to_target_interval,
                       0,nrStimuli-1)
      if i == sequences_for_break:
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
def sendEvent(event_type, event_value=1, offset=0):
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
            newevents = ftc.getEvents([nEvents,curEvents])
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
    print('Trying to connect to buffer on %s:%i ...'%(hostname,port))
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
        print(hdr.labels)
  
fSample = hdr.fSample

# set  up pygame and PyAudio
if os.name == 'posix':
    pygame.mixer.pre_init(44100, -16, 1, 128) # set audio minimual buffer = fast startup
else:
    pygame.mixer.pre_init(44100, -16, 1, 1024) # set audio minimual buffer = fast startup

pygame.init()
#pygame.mixer.set_num_channels(1) # limit to one sound playing at a time
stimulusChan = pygame.mixer.Channel(0) # get and reserve single channel for all stimulus to play on
pygame.mixer.set_reserved(1)

# set up the window
if fullscreen:
  windowSurface = pygame.display.set_mode(pygame.display.list_modes()[0], pygame.FULLSCREEN, 32)
else:
  windowSurface = pygame.display.set_mode((640,480),  1, 32)
  
pygame.display.set_caption('BCI Music Experiment')

## LOADING GLOBAL VARIABLES

# Pre-Loading Music data
names     = ['500', '505', '510', '515', '520', '525', '530', '535', '540', '545', '550']
nrStimuli = len(names)
sounds = map(lambda i: pygame.mixer.Sound("stimuli/" + names[i] + ".wav"), range(0,nrStimuli))

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
actions_key[K_s] = lambda: playSingleStimulus(0)
actions_key[K_1] = lambda: playSingleStimulus(0)
actions_key[K_2] = lambda: playSingleStimulus(1)
actions_key[K_3] = lambda: playSingleStimulus(2)
actions_key[K_4] = lambda: playSingleStimulus(3)
actions_key[K_5] = lambda: playSingleStimulus(4)
actions_key[K_6] = lambda: playSingleStimulus(5)
actions_key[K_7] = lambda: playSingleStimulus(6)

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