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
number_of_epochs = 14

#The number of stimuli to play.
number_of_stimuli = 6

#The number of times to repeat each stimulus in a training sequence
number_of_repeats = 3

# set to true for keyboard control of the experimental progression
keyboard = True

sequence_duration         = 15
testing_sequence_duration = 120
inter_stimulus_interval   = .3
target_to_target_interval = 1
baseline_duration         = 3
target_duration           = 2
inter_trial_duration      = 3
sequences_for_break       = 3

# flag to indicate we should end training/testing early
endSeq=False

## END OF CONFIGURABLE VARIABLES
import pygame, sys
from pygame.locals import *
from random import shuffle, randint, random
from time import sleep, time
import os
sys.path.append(os.path.dirname(__file__) + bufferpath)
import FieldTrip
sys.path.append(os.path.dirname(__file__) + sigProcPath)
import stimseq

## HELPER FUNCTIONS
def updateframe(string, big=False, center=False):
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
        if center: textRect.centerx = windowSurface.get_rect().centerx

        textRect.centery = windowSurface.get_rect().centery - offset
        offset -= textRect.h

        # draw the text onto the surface
        windowSurface.blit(t, textRect)

    # draw the window onto the screen
    pygame.display.update()
    pygame.display.update()

def close():
    pygame.quit()
    #sys.exit()
    
def playSingleStimulus(i):
    sendEvent("stimulus.online.play", names[i])
    stimulusChan.play(sounds[i])
    # wait for the audio to finish
    while stimulusChan.get_busy()>0 : 
        sleep(0.1);
    sendEvent("stimulus.online", "end", 0)

def runTrainingEpoch(nEpoch,seqDur,isi,tti,distID,tgtID):
    dobreak(baseline_duration, ["Get Ready"]+["Training Epoch " + str(nEpoch)])
    updateframe("+", True, True)

    updateframe(["Target Sound: " + names[tgtID]],False,True)
    sleep(target_duration/2.0)
    t0=time()
    for ei in range(3): # play 3 beeps of the target sound at the target interval
        ttg = (t0+ei*tti/2.0)-time()
        if ttg>0 : playSlience(ttg,stream)  # avoid clicks by playing slience...
        stream.write(data[tgtID])
    sleep(target_duration/2.0)      
    updateframe("+", True, True)

    ## Set up training sequence
    ss = stimseq.StimSeq.mkStimSeqOddball(1,seqDur,isi,tti)
    
    ## get num targets
    nTgt=0; 
    for s in ss.stimSeq: nTgt+= 1 if s[0]==1 else 0

    # play the stimulus sequence
    sendEvent("stimulus.trial", "start")
    sendEvent("stimulus.numTargets", nTgt)
    sendEvent("stimulus.targetID", names[tgtID])
    
    t0=time()
    for ei in range(0,len(ss.stimTime_ms)):
        st  = ss.stimTime_ms[ei]
        ssi = ss.stimSeq[ei]
        tgt = ssi[0]==1
        audioID = tgtID if tgt else distID

        # sleep until we should play this sound
        ttg = (t0+st/1000.0)-time()
        if ttg>0 : 
            sleep(ttg) 
        else: 
            print(str(time()-t0) + ") Lagging behind! tn=" + str(st/1000) + " ttg=" + str(ttg));
        # send events as close in time as possible to when the actual stimulus starts
        sendEvent("stimulus.target", tgt)   # target/non-target
        sendEvent("stimulus.play", names[audioID]) # which stimulus
        stimulusChan.play(sounds[audioID])

    # get user count of targets
    sleep(0.5)
    getFeedback("How many 'odd' beeps?",int(len(ss.stimTime_ms)/2),nTgt)
    sendEvent("stimulus.trail","end")

def runTestingEpoch(nEpoch,seqDur,isi,tti,audioIDs,tgtIdx=None):
    global endSeq
    if tgtIdx is None: tgtIdx=len(audioIDs)-1
    dobreak(baseline_duration, ["Get Ready"]+["Testing Epoch " + str(nEpoch)])

    updateframe(["Target: " + names[audioIDs[tgtIdx]]],False,True)
    sleep(target_duration/2.0)
    t0=time()
    for ei in range(3): # play 3 beeps of the target sound at the target interval
        ttg = (t0+ei*tti/2.0)-time()
        if ttg>0 : playSlience(ttg,stream)  # avoid clicks by playing slience...
        #sleep(ttg if ttg>0 else 0) 
        stream.write(data[audioIDs[tgtIdx]])
    sleep(target_duration/2.0)      

    ## Set up training sequence
    ss = stimseq.StimSeq.mkStimSeqOddball(1,seqDur,isi,tti)
    
    # play the stimulus sequence
    sendEvent("stimulus.trial", "start")
    sendEvent("stimulus.targetID", names[audioIDs[tgtIdx]])
    
    endSeq=False
    t0=time()
    for ei in range(0,len(ss.stimTime_ms)):
        st  = ss.stimTime_ms[ei]
        ssi = ss.stimSeq[ei]
        tgt = ssi[0]==1
        
        # update the target sound based on pressed keys..
        newTgt=False
        events = pygame.event.get()
        for event in events:
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    endSeq=True
                if event.key in numKeyDict : 
                    ntgtIdx = numKeyDict[event.key]
                    if ntgtIdx < len(audioIDs)-1:
                        tgtIdx = ntgtIdx+1
                        newTgt = True
        if endSeq : break
        if newTgt: updateframe(["Target: " + names[audioIDs[tgtIdx]]],False,True)

        # sleep until we should play this sound
        ttg = (t0+st/1000.0)-time()
        if ttg>0 : 
            #if sys.platform=='win32' or sys.platform=='win64':
                playSlience(ttg,stream)  # avoid clicks on windows by playing slience...
            #else:
            #    sleep(ttg) 
        else: 
            print(str(time()-t0) + ") Lagging behind! tn=" + str(st/1000) + " ttg=" + str(ttg));

        # send events as close in time as possible to when the actual stimulus starts
        audioID = audioIDs[tgtIdx if tgt else 0]
        sendEvent("stimulus.target", tgt)   # target/non-target
        sendEvent("stimulus.play", names[audioID]) # which stimulus
        stream.write(data[audioID]) # this should block until the audio is finished....

    sleep(0.5)
    if not endSeq:
        # get user count of targets
        getFeedback("How many 'odd' beeps?",int(len(ss.stimTime_ms)/2),nTgt)
    sendEvent("stimulus.trail","end")

def getFeedback(prompt,maxLowered,trueLowered):
    global endSeq
    updateframe([prompt, "0-" + str(maxLowered)], False)
    key=[None]*2
    for i in range(2):
        key[i] = waitForKey()
        while not (key[i] in numKeyDict or key[i]==pygame.K_ESCAPE):
            key[i] = waitForKey()
        print("Got key: " + str(key[i]) + "\n")                
        if key[i]==pygame.K_ESCAPE:
            endSeq=True # mark that we should stop
            return None # abort
    respLowered=int(str(numKeyDict[key[0]]))*10 + int(str(numKeyDict[key[1]]))
    sendEvent("response.numTargets", respLowered)
    fbStr = [];
    if respLowered == trueLowered: fbStr += ["Correct!"]
    else:                          fbStr += ["Wrong!"]
    updateframe(fbStr + ["Response = " + str(respLowered)] 
                + ["True fragments = " + str(trueLowered)])
    sleep(1)
    return respLowered
    
def dobreak(n, message):
    while n > 0:
        updateframe(message + [" "] + [str(n)],False,True)
        sleep(0.1)
        n -= 0.1

def showInstructions():
  instructions = ["The training phase of the experiment will last about " + str(number_of_epochs) + " minutes.",
                  "About once every minute there will be a short break.",
                  "During training please focus on the spot on the screen",
                  "and try to count the number of 'odd' sounds you hear.",
                  "Try not to blink!","","Press key to continue."]

  updateframe(instructions,False,False)
  waitForKey()

def showKeyboardInstructions():
    instructions=["Press:", 
                  " i - show expt instructions",
                  " e - show eeg Viewer",
                  " o - audio oddball training",
                  " t - audio oddball testing",
                  " esc - quit", 
                  " 1..7 - play stimulus 1..7"]
    updateframe(instructions)

def showeeg():
    sendEvent('startPhase.cmd','eegviewer')

def doTraining():
  sendEvent('startPhase.cmd','erpvis')
  sendEvent('stimulus.training','start')
  for i in range(1,(number_of_epochs+1)):
      # run with given parameters, and max audio difference
      runTrainingEpoch(i,sequence_duration,inter_stimulus_interval,target_to_target_interval,
                       0,nrStimuli-1)
      if i == sequences_for_break:
          updateframe(["Long Break","Press space to continue"])
          waitForSpaceKey()
      elif i!= number_of_epochs:
          updateframe("")
          sleep(inter_trial_duration)

      if endSeq : break    


  updateframe("Training Finished")
  sleep(2)
  sendEvent('erpvis','end')
  sendEvent('stimulus.training','end')


def doTesting():
  sendEvent('startPhase.cmd','erpvis')
  sendEvent('stimulus.testing','start')
  # run with given parameters, and max audio difference
  runTestingEpoch(0,testing_sequence_duration,inter_stimulus_interval,target_to_target_interval,
                  range(nrStimuli))

  updateframe("Training Finished")
  sleep(2)
  sendEvent('erpvis','end')
  sendEvent('stimulus.testing','end')
  

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
  
pygame.display.set_caption('BCI Audio OddBall Experiment')

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
updateframe(["Welcome to the Oddball Music Experiment"])

#

numKeyDict = {K_0 : 0, K_1 : 1, K_2 : 2, K_3 : 3, K_4 : 4, K_5 : 5, K_6 : 6, K_7 : 7, K_8 : 8, K_9 : 9, K_KP0 : 0, K_KP1 : 1, K_KP2 : 2, K_KP3 : 3, K_KP4 : 4, K_KP5 : 5, K_KP6 : 6, K_KP7 : 7, K_KP8 : 8, K_KP9 : 9 } 

actions_key = dict()
actions_key[K_e] = showeeg
actions_key[K_i] = showInstructions
actions_key[K_o] = doTraining
actions_key[K_t] = doTesting
actions_key[K_q] = close
actions_key[K_ESCAPE] = close
actions_key[K_s] = lambda: playSingleStimulus(0)
actions_key[K_1] = lambda: playSingleStimulus(0)
actions_key[K_2] = lambda: playSingleStimulus(1)
actions_key[K_3] = lambda: playSingleStimulus(2)
actions_key[K_4] = lambda: playSingleStimulus(3)
actions_key[K_5] = lambda: playSingleStimulus(4)
actions_key[K_6] = lambda: playSingleStimulus(5)
actions_key[K_7] = lambda: playSingleStimulus(6)

## STARTING PROGRAM LOOP
while True:
    showKeyboardInstructions()
    key = waitForKey()
    #print("Got key: " + str(key) + "\n")
    if key in actions_key:
        actions_key[key]()
