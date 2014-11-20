# import necessary libraries from Psychopy and buffer_bci-master
from psychopy import visual, core, event, gui, sound, data, monitors
from random import shuffle
import numpy as np
import struct, sys, time
sys.path.append("../../dataAcq/buffer/python/")
import FieldTrip

# ************** Set up buffer connection **************
# set hostname and port of the computer running the fieldtrip buffer.
hostname='localhost'
port=1972

# function to send events to data buffer
# use as: sendEvent("markername", markernumber, offset)
def sendEvent(event_type, event_value, offset=0):
    e = FieldTrip.Event()
    e.type = event_type
    e.value = event_value
    sample, bla = ftc.poll()
    e.sample = sample + offset + 1
    ftc.putEvents(e)

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
        core.wait(1)
    else:
        print hdr
        print hdr.labels

fSample = hdr.fSample


# ************** Set up stimulus screen and set experiment parameters **************
#present a dialogue to provide the current participant code
ppcode = {'Participant':01}
dlg = gui.DlgFromDict(ppcode, title='Experiment', fixed=['01'])
if dlg.OK:
    # create a text file to save the experiment data
    savefile = open("logfiles/pp"+str(ppcode['Participant'])+".txt","w")
    savefile.write("Trial \t Participant \t Image \t MaxTime(sec) \t Played \t SoundOnset(sec) \t" +
        "AudioStart(sec) \t AudioEnd(sec) \t RT(sec) \t Answer(1=yes, 0=no, -1=empty) \n")
else:
    core.quit() #the user hit cancel so exit

# Setup the stimulus window
mywin = visual.Window(size=(1920, 1080), fullscr=True, screen=0, allowGUI=False, allowStencil=False,
    monitor='testMonitor', units="pix",color=[0,0,0], colorSpace='rgb',blendMode='avg', useFBO=True)

#create some stimuli
instruction = visual.TextStim(mywin, text='Welcome!\n\n' +
            'You will view a sequence of images, each displaying an object.\n'+
            'When you recognize the object in the image, press SPACE with your right hand in order to continue to the next image.\n\n' +
            'When you hear a beep while you are looking at an image and:\n' +
            '(1) you already intended to press SPACE: do NOT press SPACE and wait fot the next image to appear.\n' +
            '(2) you did not yet intend to press SPACE: ignore the beep and continue what you were doing.\n\n' +
            'This experiment will last about 10 minutes.\n' +
            'Please try to blink and move as little as possible while there is an image present on the screen.\n\n' +
            'Good luck!',color=(1,1,1),wrapWidth = 800) # instructions
fixation = visual.TextStim(mywin, text='+',color=(1,1,1),height=40) # fixation cross
breaktext = visual.TextStim(mywin, text='Break\n\nPress a button to continue...',color=(1,1,1)) # break
thankyou = visual.TextStim(mywin, text='End of the experiment',color=(1,1,1)) # thank you screen
question = visual.TextStim(mywin, text='Did you already intend to press SPACE when you heard the beep? \n [z = JA] [m = NEE]',color=(1,1,1)) # intention question
beep = sound.SoundPyo(value='C',secs=0.2,octave=5,stereo=True,volume=1.0,loops=0,sampleRate=44100,bits=16,hamming=True,start=0,stop=-1) # beep sound

#set experiment parameters
nr_images = 15
opacity = np.arange(0.0,1.0,0.025)
sizeMask = 8
nr_trials_per_block = 5
nr_blocks = 3
current_trial = 0
current_block = 1
order = list(xrange(1,nr_images+1))
print "Order", order
shuffle(order)
timer = core.Clock()

# ************** Start experiment **************
# Show instruction
instruction.draw()
mywin.flip()
# wait for key-press
allKeys = event.getKeys()
while len(allKeys)==0:
    allKeys = event.getKeys()
if 'escape' in allKeys[0]:
    mywin.close() # quit
    core.quit()

# Run through trials
print "Total number of trials = " + str(nr_images)
for block in range (1,nr_blocks+1):
    sendEvent("experiment.block","Block_"+str(block))
    for trial in range (0,nr_trials_per_block):
        print "Current trial = ", current_trial
        # set current image and image mask
        image = visual.ImageStim(mywin, image="stimuli_BOSS_database/IMG" + str(order[current_trial]) + ".png") # set current image
        image.setSize([500,500])
        myTex = np.random.choice([0.0,1.0],size=(sizeMask,sizeMask),p=[1./10,9./10])
        myStim = visual.GratingStim(mywin, tex=None, mask=myTex, size=image.size)
        
        # determine max trial length (between 10 and 15 seconds)
        maxTime = (15-10)*np.random.random()+10
        print "Max time = ", maxTime
        
        # determine random sound onset between 2 and MaxTime-1 seconds after trial start
        soundOnset = ((maxTime-1)-2)*np.random.random()+3
        print "Sound onset = ", soundOnset
        
        allKeys = [] # forget Keyboard history
        answer = -1 
        soundStart = -1
        rt = -1
        soundEnd = -1
        endTrial = False # trial still running
        done = False # no butten press yet
        empty = False # image is still masked
        played = False # sound is not played yet
        timestep = 0.05 # image mask disapperes a bit each 5ms
        idx = len(opacity)-1
        current_time = timestep 
        x = np.random.randint(sizeMask) # which part of image mask should disappear
        y = np.random.randint(sizeMask) # which part of image mask should disappear
        while myTex[x][y] == 0:
            x = np.random.randint(sizeMask)
            y = np.random.randint(sizeMask)

        # present fixation cross for 200ms
        sendEvent("experiment.trial","Trial_"+str(current_trial))
        fixation.draw()
        mywin.flip()
        sendEvent("stimulus.fixationcross","start")
        core.wait(0.2)
        sendEvent("stimulus.fixationcross","end")

        # present image
        image.draw()
        myStim.draw()
        mywin.flip()
        sendEvent("stimulus.image","start")
        timer.reset()

        while done is False and endTrial is False: 
            if timer.getTime() >= maxTime:
                endTrial = True
                question.draw()
                mywin.flip()
                allKeys = event.getKeys()
                while len(allKeys)<1:
                   allKeys = event.getKeys()
                if allKeys[0] == 'z':
                   sendEvent("response.question","yes")
                   answer = 1
                else:
                   sendEvent("response.question","no")
                   answer = 0
            else:
                allKeys = event.getKeys()
                if timer.getTime() >= soundOnset and played is False:
                   sendEvent("stimulus.beep","start")
                   soundStart = timer.getTime()
                   beep.play()
                   sendEvent("stimulus.beep","end")
                   soundEnd = timer.getTime()
                   played = True
                if len(allKeys)>0:
                   if allKeys[0] == 'space':
                        sendEvent("response.space","pressed")
                        rt = timer.getTime()
                        done = 1 # button press
                   elif 'escape' in allKeys[0]:
                        mywin.close() # quit
                        core.quit()
                elif timer.getTime() >= current_time and empty is False:
                   current_time += timestep
                   myTex[x][y] = opacity[idx]
                   idx -= 1
                   myStim = visual.GratingStim(mywin, tex=None, mask=myTex, size=image.size)
                   image.draw()
                   myStim.draw()
                   mywin.flip()
                   if idx == -1:
                        if 1 in myTex:
                           idx = len(opacity)-1
                           x = np.random.randint(sizeMask) # get new part of mask to disappear
                           y = np.random.randint(sizeMask) # get new part of mask to disappear
                           while myTex[x][y] == 0:
                               x = np.random.randint(sizeMask)
                               y = np.random.randint(sizeMask)
                        else:
                           empty = True
        # save data to file
        savefile.write(str(current_trial) + "\t" + str(ppcode['Participant']) +"\t" + "IMG" + str(order[current_trial]) + ".png" + "\t" +
            str(round(maxTime,3)) + "\t" + str(played) + "\t" + str(round(soundOnset,3)) + "\t" + str(round(soundStart,3)) + "\t" + 
            str(round(soundEnd,3)) + "\t" + str(round(rt,3)) + "\t" + str(answer) + "\n")
        mywin.flip()
        core.wait(0.2)
        current_trial += 1
    if block < nr_blocks:
        # break
        breaktext.draw()
        mywin.flip()
        # wait for key-press
        allKeys = event.getKeys()
        while len(allKeys)==0:
            allKeys = event.getKeys()

# ************** End of experiment **************
thankyou.draw()
mywin.flip()
core.wait(2)

#cleanup
mywin.close()
ftc.disconnect()
core.quit()
sys.exit()
