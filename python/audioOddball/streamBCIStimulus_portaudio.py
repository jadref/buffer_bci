#!/usr/bin/python

# TODO: 
#  [] - Add BCI testing phase, which just runs for a long time

## CONFIGURABLE VARIABLES
# Path of the folder containing the buffer client
bufferpath = "../../dataAcq/buffer/python"
sigProcPath = "../signalProc"

# Connection options of fieldtrip, hostname and port of the computer running the fieldtrip buffer.
hostname='localhost'
port=1972

#Set to True if the program has to run in fullscreen mode.
fullscreen = False #True

number_of_sequences       = 14
sequence_duration         = 15
testing_sequence_duration = 120
inter_stimulus_interval   = .15 # =frame-rate, something happens every this many seconds
baseline_duration         = 2
target_duration           = 2
inter_sequence_duration   = 2
sequences_for_break       = number_of_sequences//2
periods                   = [x*inter_stimulus_interval for x in [3,4]] #interval between left/right stimuli

# flag to indicate we should end training/testing early
endSeq=False

## END OF CONFIGURABLE VARIABLES
import pygame, sys
from pygame.locals import *
from random import shuffle, randint, random
from time import sleep, time
from pyaudio import PyAudio
import wave
import os
sys.path.append(os.path.dirname(__file__)+bufferpath)
import FieldTrip
sys.path.append(os.path.dirname(__file__)+sigProcPath)
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

# Audio Manipulation functions
import array;
def rebalance(data,sampwidth,balance):
    ''' data in stereo audio data and re-balance the left-right mapping'''
    # convert the raw bytes into an integer array
    a=[];
    if sampwidth == 1 :
         a=array.array("b",data) 
    elif sampwidth == 2:
         a=array.array("h",data) #get as short integer data         
    # transform the volume in the array
    for j in range(0,len(a)-1,2): # N.B. audio is interleaved in left-right pairs
        a[j]   = int(a[j]  *balance)
        a[j+1] = int(a[j+1]*(1-balance))  
    return a;

def playSlience(duration,stream):
    channels=stream._channels
    rate    =stream._rate
    sampWidth=p.get_sample_size(stream._format)
    nByte   =int(duration*channels*sampWidth*rate)
    audio   ='\0'*nByte
    stream.write(audio) # blocking call

def close():
    pygame.quit()
    stream.stop_stream()
    stream.close()
    p.terminate()
    sendEvent('startPhase.cmd','exit')
    #sys.exit()
    
def playSingleStimulus(i):
    offset = stream.get_output_latency()*fSample
    sendEvent("stimulus.online.play", names[i], offset)
    stream.write(data[i])
    sleep(0.5);
    sendEvent("stimulus.online", "end", 0)

def runBCITrainingEpoch(nEpoch,names,data,seqDur,isi,periods,audioIDs,tgtIdx):

    # spatialize the audio into left/right channels, and convert to an integer array
    audioArray   =[None]*2
    audioArray[0]=rebalance(data[audioIDs[0]],sounds[audioIDs[0]].getsampwidth(), 0)
    audioArray[1]=rebalance(data[audioIDs[1]],sounds[audioIDs[1]].getsampwidth(), 1)

    dobreak(baseline_duration, ["Get Ready","Training Epoch " + str(nEpoch)])

    # display the cue to the subject for the target for this sequence
    updateframe(["Target Sound: " + str(audioIDs[tgtIdx])] + ["->" if tgtIdx==0 else "<-"],False,True)
    sleep(target_duration/2.0)
    t0=time()
    for ei in range(3): # play 3 beeps of the target sound at the target interval
        ttg = (t0+ei*1.0*periods[tgtIdx])-time()
        if ttg>0 : playSlience(ttg,stream)  # avoid clicks by playing slience...
        #sleep(ttg if ttg>0 else 0) 
        stream.write(audioArray[tgtIdx].tostring())
    sleep(target_duration/2.0)      
    updateframe("+", True, True)

    ## Set up training sequence, 2 stim different intervals
    ## N.B. stimilus 0 is always assumed to be the target
    ss = stimseq.StimSeq.mkStimSeqInterval(2,seqDur,isi,periods)
    
    ## get num targets
    nTgt=0; 
    for s in ss.stimSeq: nTgt+= 1 if s[0]==1 else 0

    # play the stimulus sequence
    sendEvent("stimulus.trial", "start")
    sendEvent("stimulus.numTargets", nTgt)
    sendEvent("stimulus.targetID", names[audioIDs[tgtIdx]])
    
    # some constants for the max amount of audio to play for one inter-stimulus-interval's worth sound
    sec2samp = stream._rate # convert time to samples
    samp2byte= stream._channels * p.get_sample_size(stream._format) # convert samples to bytes
    isi_bytes= int(isi * sec2samp) * samp2byte # number bytes, N.B. always get integer #samples first
    cursori=[-1,-1] #current position in each of the stimulus streams, negative value means not started

    t0=time()
    for ei in range(0,len(ss.stimTime_ms)):
        st  = ss.stimTime_ms[ei]
        ssei= ss.stimSeq[ei]
        ssei= [x if not x is None else 0 for x in ssei] # convert None=>0
        audioID = filter(lambda(ai): ssei[ai]==1, range(len(ssei)))
        tgt = ssei[tgtIdx]==1  # target stimuli if played the target stimuli

        # set any new audio to start playing, restart if already playing
        for i in audioID: cursori[i]=0
        # get the list of audio fragements with something to play
        playID = filter(lambda(ai): cursori[ai]>=0, range(len(cursori)))
        audio=None
        if len(playID)>0: # if something to play
            #print(str(i) + ") cursor" + str(cursori) + " ssei " + str(ssei))
            # only make enough audio to fill to the next isi time-point
            ttg = (t0+st/1000.0)-time()
            nbytes = isi_bytes
            # lagging behind, make a shorter audio fragement
            if ttg<0 : nbytes = max(0,int((isi+ttg)*sec2samp))*samp2byte;
            # mix the fragments to make the audio we play
            audio = array.array(audioArray[0].typecode)
            audioappend = audio.append
            for i in range(nbytes): # loop over samples with max isi_samp bytes at a time
                # stop building audio if nothing to play
                # (so we have a chance to catch-up if we run behind the play schedule)
                if len(playID)==0 : break; 
                datai=0
                for fragi in playID: # loop over fragements with something to play
                    # add in the activated audio
                    datai += audioArray[fragi][cursori[fragi]]
                    # move on the playback cursor for this fragement
                    cursori[fragi] += 1
                    # if past end of this fragement turn off this fragement and update the
                    # list of fragements to play
                    if cursori[fragi]>=len(audioArray[fragi]) :
                        cursori[fragi]=-1
                        playID = filter(lambda(ai): cursori[ai]>=0, range(len(cursori)))
                audioappend(datai) # put the combined audio into the audio stream
                
        # play slience until we should play this sound
        ttg = (t0+st/1000.0)-time()
        if ttg>0 :
            playSlience(ttg,stream)  # avoid clicks on windows by playing slience...
        else: # if lagging behind then drop this frame!
            print(str(time()-t0) + ") Lagging behind! tn=" + str(st/1000) + " ttg=" + str(ttg));

        # send events as close in time as possible to when the actual stimulus starts
        if len(audioID)>0: # if something to play
            sendEvent("stimulus.target", [1 if tgt==1 else -1])     # target/non-target sound
            sendEvent("stimulus.play", names[audioIDs[audioID[0]]]) # which stimulus
        else:
            sendEvent("stimulus.target",0) # non-target, no-sound
        # acutally play the audio we need to play
        if not audio is None:
            # this should block until just before the audio is finished, then we have a little
            # time to get the next piece of audio ready and into the play buffer.
            # Q: how much time? as this defines the offset between audio and events..
            stream.write(audio.tostring()) 
            
    # # get user count of targets
    # sleep(0.5)
    # getFeedback("How many 'target' beeps?",int(len(ss.stimTime_ms)/2),nTgt)
    sendEvent("stimulus.trial","end")

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
  instructions = ["The training phase of the experiment will last about " + str(number_of_sequences) + " minutes.",
                  "About once every minute there will be a short break.",
                  "During training please focus on the spot on the screen",
                  "and try to count the number of 'odd' sounds you hear.",
                  "Try not to blink!","","Press key to continue."]

  updateframe(instructions,False,False)
  waitForKey()

def showeeg():
    sendEvent('startPhase.cmd','eegviewer')

def doBCITraining(names,data,periods):
  sendEvent('startPhase.cmd','calibrate')
  sendEvent('stimulus.training','start')
  stimIDs=[0,len(data)-1]
  stimi = list(stimIDs) # left/right position for each sequence
  periodsi=list(periods)
  for i in range(1,(number_of_sequences+1)):
      # Pick a target sound for this sequence      
      shuffle(stimi)    # N.B. shuffle modifies in place....
      tgtIdx = randint(0,1)
      # randomly shuffle who gets what period
      shuffle(periodsi) # N.B. shuffle modifies in place...

      # run with given parameters, and max audio difference      
      runBCITrainingEpoch(i,names,data,sequence_duration,inter_stimulus_interval,periodsi,stimi,tgtIdx)
      if i == sequences_for_break:
          updateframe(["Long Break","Press space to continue"])
          waitForSpaceKey()
      elif i!= number_of_sequences:
          updateframe("")
          sleep(inter_sequence_duration)

      if endSeq : break    
           
  updateframe("Training Finished")
  sleep(2)
  sendEvent('calibrate','end')

def bciTesting(names,data,periods):
  sendEvent('startPhase.cmd','testing')
  sendEvent('stimulus.testing','start')
  stimIDs=[0,len(data)-1]
  for i in range(1,(number_of_sequences+1)):
      # Pick a target sound for this sequence      
      tgtIdx = randint(0,1)
      # randomly shuffle who gets what period
      shuffle(periodsi) # N.B. shuffle modifies in place...

      # run with given parameters, and max audio difference      
      runBCITrainingEpoch(i,names,data,testing_sequence_duration,inter_stimulus_interval,periodsi,stimi,tgtIdx)
      if i == sequences_for_break:
          updateframe(["Long Break","Press space to continue"])
          waitForSpaceKey()
      elif i!= number_of_sequences:
          updateframe("")
          sleep(inter_sequence_duration)

      if endSeq : break    

  updateframe("Testing Finished")
  sleep(2)
  sendEvent('testing','end')
  
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
pygame.init()
p = PyAudio()

# set up the window
if fullscreen:
  windowSurface = pygame.display.set_mode(pygame.display.list_modes()[0], pygame.FULLSCREEN, 32)
else:
  windowSurface = pygame.display.set_mode((640,480),  1, 32)
  
pygame.display.set_caption('BCI Audio OddBall Experiment')

## LOADING GLOBAL VARIABLES

# Pre-Loading Music data
names   = ['500', '505', '510', '515', '520', '525', '530', '535', '540', '545', '550']
sounds  = map(lambda i: wave.open("stimuli/" + names[i] + ".wav"), range(0,len(names)))
data    = map(lambda x: x.readframes(x.getnframes()),sounds)

# Pre-loading yes/no data
ynnames   = ['no_f', 'yes_m']
ynsounds  = map(lambda i: wave.open("stimuli_yesno/" + ynnames[i] + ".wav"), range(0,len(ynnames)))
yndata    = map(lambda x: x.readframes(x.getnframes()),ynsounds)

# Opening Audio Stream
print("tone  width " + str(sounds[0].getsampwidth()) + " framerate " + str(sounds[0]._framerate) + " nch " + str(sounds[0].getnchannels()));
print("yesno width " + str(ynsounds[0].getsampwidth()) + " framerate " + str(ynsounds[0]._framerate) + " nch " + str(ynsounds[0].getnchannels()));
stream = p.open(format=p.get_format_from_width(sounds[0].getsampwidth()),
            channels=sounds[0].getnchannels(),
            rate=sounds[0].getframerate(),
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


def showKeyboardInstructions():
    instructions=["Press:", 
                  " i - show expt instructions",
                  " e - show eeg Viewer",
                  " c - BCI calibration",
                  " t - BCI testing",
                  " y - BCI yes/no training",
                  " b - BCI yes/no testing",
                  " esc - quit", 
                  " 1..7 - play stimulus 1..7"]
    updateframe(instructions)

actions_key = dict()
actions_key[K_e] = showeeg
actions_key[K_i] = showInstructions
actions_key[K_c] = lambda : doBCITraining(names,data,periods)
actions_key[K_t] = lambda : bciTesting(names,data,periods)
actions_key[K_y] = lambda : doBCITraining(ynnames,yndata,periods)
actions_key[K_b] = lambda : bciTesting(ynnames,yndata,periods)
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
    print("Got key: " + str(key) + "\n")
    if key in actions_key:
        actions_key[key]()
