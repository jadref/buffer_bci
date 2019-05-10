#!/usr/bin/env python3
# Set up imports and paths
bufferpath = "../../dataAcq/buffer/python"
sigProcPath = "../signalProc"
from psychopy import visual, core, event, gui, sound, data, monitors
import numpy as np
import sys
from time import sleep, time
import os
bufhelpPath = "../../python/signalProc"
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),bufhelpPath))
import bufhelp
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),sigProcPath))

# init connection to the buffer
ftc,hdr=bufhelp.connect();

# show some text on the screen
def showText(text):
    text.draw()
    mywin.flip()

# wait for user to press a button and return what button it was
def waitForKeypress():
    allKeys = event.getKeys()
    while len(allKeys)==0:
        allKeys = event.getKeys()
    return allKeys

# navigate through a house in a wheelchair (listens to commands: navigate.up, navigate.down, navigate.left, navigate.right, navigate.end)
def navigate(path,navigation,error,get_ready,sos):
    errors = 0
    error_sos = 0
    sos_time = 0
    timer = core.Clock()
    
    current_image = visual.ImageStim(mywin, image="png/navigation1.png") # set image
    current_image.draw()
    get_ready.text ='Navigate from the front door to the couch using events of type "navigate" with values "left","right","down" and "up". Each dot represents one required event.\n\nNote: each error will add 15s to your total time. \n\nPress any key to start'
    showText(get_ready)
    keys = waitForKeypress()
    
    mywin.flip()
    current_image.draw()
    mywin.flip()
    timer.reset()
    
    triggerevents=["navigate"]
    stopevent=("navigate","end")
    trlen_samp = 50
    state = []
    endNavigate = False
    current_idx = 0
    print("Waiting for triggers: %s and endtrigger: %s.%s"%(triggerevents[0],stopevent[0],stopevent[1]))
    while endNavigate is False:
        # grab data after every t:'stimulus' event until we get a {t:'stimulus.training' v:'end'} event 
        #data, events, stopevents, state = bufhelp.gatherdata(triggerevents,trlen_samp,stopevent, state, milliseconds=False)
        data, events, stopevents, state = bufhelp.gatherdata(triggerevents,trlen_samp,[], state, milliseconds=False)
        for ei in np.arange(len(events)-1,-1,-1):
            ev = events[ei]
            if ev.type == "navigate":
                if ev.value == path[current_idx]:
                    current_idx = current_idx + 1
                    current_image = visual.ImageStim(mywin, navigation[current_idx]) # set image
                else:
                    current_image = visual.ImageStim(mywin, error[current_idx]) # set image
                    errors = errors+1
                current_image.draw()
                mywin.flip()
            if current_idx == len(navigation)-1:
                current_image = visual.ImageStim(mywin, "png/navigation_done.png") # set image
                current_image.draw()
                mywin.flip()
                core.wait(2)
                endNavigate = True
            if current_idx > 5 and sos:
                [sos_time,error_sos] = sos_button(get_ready,current_image)
                sos = False
    return [timer.getTime(),errors, error_sos, sos_time]

# browse tv channels. When all channels are seen once, the "preferref" channel is highlighted when visited for a second time.
# User needs to watch preferred channel for at least min_time. User can stop watching by sending tv.end event. 
# (listens to commands: tv.1, tv.2, tv.3 and tv.end)
def watch_tv(channel,min_time,get_ready,sos):
    errors = 0
    error_sos = 0
    sos_time = 0
    
    timer = core.Clock()
    current_image = visual.ImageStim(mywin, image="png/tv.png") # set image
    current_image.draw()
    get_ready.text ='You want to watch tv. First go through each channel using events of type "tv" and value "1", "2" and "3". Then, go through each channel for a second time until you see a channel with a green mark next to it. This is the preferred channel. Look at this channel for at least 30s without changing channels. After 30s, turn off the tv using an event of type "tv" with the value "end". \n\nNote: each error will add 5s to your total time.\n\nPress any key to start'
    showText(get_ready)
    keys = waitForKeypress()
    
    mywin.flip()
    current_image.draw()
    mywin.flip()
    timer.reset()
    
    triggerevents=["tv"]
    stopevent=("tv","end")
    trlen_samp = 50
    state = []
    endTV = False
    current_idx = 0
    channels_seen = [False, False, False]
    channel_timer = core.Clock()
    start_counting = False
    print("Waiting for triggers: %s and endtrigger: %s.%s"%(triggerevents[0],stopevent[0],stopevent[1]))
    while endTV is False:
        # grab data after every t:'stimulus' event until we get a {t:'stimulus.training' v:'end'} event 
        #data, events, stopevents, state = bufhelp.gatherdata(triggerevents,trlen_samp,stopevent, state, milliseconds=False)
        data, events, stopevents, state = bufhelp.gatherdata(triggerevents,trlen_samp,[], state, milliseconds=False)
        channel_update = False
        for ei in np.arange(len(events)-1,-1,-1):
            ev = events[ei]
            if ev.type == "tv":
                if ev.value == "1":
                    current_image = visual.ImageStim(mywin, "png/tv_nature.png") # set image
                    if channels_seen[0] is False:
                        channels_seen[0] = True
                        channel_update = True
                elif ev.value == "2":
                    current_image = visual.ImageStim(mywin, "png/tv_mes_op_tafel.png") # set image
                    if channels_seen[1] is False:
                        channels_seen[1] = True
                        channel_update = True
                    if sos:
                        [sos_time,error_sos] = sos_button(get_ready,current_image)
                        sos = False
                elif ev.value == "3":
                    current_image = visual.ImageStim(mywin, "png/tv_sesamstraat.png") # set image
                    if channels_seen[2] is False:
                        channels_seen[2] = True
                        channel_update = True
                current_image.draw()
                mywin.flip()
            if (channel_update is False) and (False not in channels_seen):
                if ev.value == channel:
                    if start_counting is False:
                        current_image = visual.ImageStim(mywin, "png/tv_done.png") # set image
                        current_image.draw()
                        mywin.flip()
                        start_counting = True
                        channel_timer.reset() # start counting time
                elif ev.value == "end":
                    if channel_timer.getTime >= min_time:
                        endTV = True
                else:
                    start_counting = False
                    print("error!")
                    errors = errors + 1
    return [timer.getTime(),errors,error_sos,sos_time]

# User needs help from a nurse to go to the bathroom, for pain treatment or for food/drinks. 
# First push SOS button, then indicate what help is needed.
def sos_button(get_ready,previous_image):
    errors = 0
    sos = ["png/sos_food.png", "png/sos_pain.png", "png/sos_toilet.png"]
    
    # choose random sos
    r = np.random.randint(len(sos))
    
    timer = core.Clock()
    current_image = visual.ImageStim(mywin, image=sos[r]) # set image
    current_image.draw()
    get_ready.text ='Emergency! You are in pain, need to go to the toilet or want food. What help you need is indicated by an icon on the screen. First press the SOS button by sending an event of type "sos" and value "on". Once the button is activated and help is on the way, select what type of help you need. You can do so with events of type "sos" and values "toilet", "pain" and "food".\n\nNote: each error will add 60s to your total time. \n\nPress any key to start'
    showText(get_ready)
    keys = waitForKeypress()
    
    mywin.flip()
    current_image.draw()
    mywin.flip()
    timer.reset()
    
    triggerevents=["sos"]
    stopevent=("sos","end")
    trlen_samp = 50
    state = []
    endSOS = False
    current_idx = 0
    print("Waiting for triggers: %s and endtrigger: %s.%s"%(triggerevents[0],stopevent[0],stopevent[1]))
    while endSOS is False:
        # grab data after every t:'stimulus' event until we get a {t:'stimulus.training' v:'end'} event 
        #data, events, stopevents, state = bufhelp.gatherdata(triggerevents,trlen_samp,stopevent, state, milliseconds=False)
        data, events, stopevents, state = bufhelp.gatherdata(triggerevents,trlen_samp,[], state, milliseconds=False)
        for ei in np.arange(len(events)-1,-1,-1):
            ev = events[ei]
            if ev.type == "sos":
                if ev.value == "on":
                    current_image = visual.ImageStim(mywin, "png/alarm_done.png") # set image
                    endSOS = True
                else:
                    current_image = visual.ImageStim(mywin, "png/alarm_error.png") # set image
                    errors = errors + 1
                current_image.draw()
                mywin.flip()
                core.wait(1)
                current_image = visual.ImageStim(mywin, image=sos[r]) # set image
                current_image.draw()
                mywin.flip()
    current_image = visual.ImageStim(mywin, "png/sos_choice.png") # set image
    current_image.draw()
    mywin.flip()
    endSOS = False
    while endSOS is False:
        # grab data after every t:'stimulus' event until we get a {t:'stimulus.training' v:'end'} event 
        #data, events, stopevents, state = bufhelp.gatherdata(triggerevents,trlen_samp,stopevent, state, milliseconds=False)
        data, events, stopevents, state = bufhelp.gatherdata(triggerevents,trlen_samp,[], state, milliseconds=False)
        for ei in np.arange(len(events)-1,-1,-1):
            ev = events[ei]
            if ev.type == "sos":
                if ev.value == "food": 
                    if r == 0:
                        current_image = visual.ImageStim(mywin, "png/food.png") # set image
                        endSOS = True
                    else:
                        current_image = visual.ImageStim(mywin, "png/food_error.png") # set image
                        errors = errors + 1
                elif ev.value == "pain":
                    if r == 1:
                        current_image = visual.ImageStim(mywin, "png/pain.png") # set image
                        endSOS = True
                    else:
                        current_image = visual.ImageStim(mywin, "png/pain_error.png") # set image
                        errors = errors + 1
                elif ev.value == "toilet":
                    if r == 2:
                        current_image = visual.ImageStim(mywin, "png/toilet.png") # set image
                        endSOS = True
                    else:
                        current_image = visual.ImageStim(mywin, "png/toilet_error.png") # set image
                        errors = errors + 1
                current_image.draw()
                mywin.flip()
            if endSOS is True:
                core.wait(3)
                previous_image.draw() # set image
                mywin.flip()
    return [timer.getTime(),errors]

# call someone: mom, Terry or Livia
def communicate(call,get_ready,sos):
    errors = 0
    error_sos = 0
    sos_time = 0
    
    timer = core.Clock()
    current_image = visual.ImageStim(mywin, image="png/mobile.png") # set image
    current_image.draw()
    get_ready.text ='You want to socialize. You can call anyone on the list using events of type "call" and values "1", "2" or "3". Right now, you want to call Livia. Note: each error will add 15s to your total time. \n\nPress any key to start'
    showText(get_ready)
    keys = waitForKeypress()
    
    mywin.flip()
    current_image.draw()
    mywin.flip()
    timer.reset()
    
    triggerevents=["call"]
    stopevent=("call","end")
    trlen_samp = 50
    state = []
    endCall = False
    current_idx = 0
    print("Waiting for triggers: %s and endtrigger: %s.%s"%(triggerevents[0],stopevent[0],stopevent[1]))
    while endCall is False:
        # grab data after every t:'stimulus' event until we get a {t:'stimulus.training' v:'end'} event 
        #data, events, stopevents, state = bufhelp.gatherdata(triggerevents,trlen_samp,stopevent, state, milliseconds=False)
        data, events, stopevents, state = bufhelp.gatherdata(triggerevents,trlen_samp,[], state, milliseconds=False)
        for ei in np.arange(len(events)-1,-1,-1):
            ev = events[ei]
            if ev.type == "call":
                if ev.value == "1":
                    current_image = visual.ImageStim(mywin, "png/mobile_mom.png") # set image
                    if sos:
                        [sos_time,error_sos] = sos_button(get_ready,current_image)
                        sos = False
                elif ev.value == "2":
                    current_image = visual.ImageStim(mywin, "png/mobile_terry.png") # set image
                else:
                    current_image = visual.ImageStim(mywin, "png/mobile_livia.png") # set image
                current_image.draw()
                mywin.flip()
            if ev.value == call:
                endCall = True
                current_image = visual.ImageStim(mywin, "png/mobile_done.png") # set image
                current_image.draw()
                mywin.flip()
                core.wait(2)
            else:
                errors = errors+1
    return [timer.getTime(),errors,error_sos,sos_time]

# Setup the stimulus window
screenWidth = 1300
screenHeight = 700 
mywin = visual.Window(size=(screenWidth, screenHeight), fullscr=False, screen=1, allowGUI=False, allowStencil=False,
    monitor='testMonitor', units="pix",color=[1,1,1], colorSpace='rgb',blendMode='avg', useFBO=True)

#create some stimuli
main_screen = visual.TextStim(mywin, text='Select task: \n\n(1) navigate \n(2) tv \n(3) toilet \n(4) communicate \n(5) demo run\n\nPress Esc to stop',color=(-1,-1,-1),wrapWidth = 800) 
goodbye = visual.TextStim(mywin, text='Bye! \n\nPress a key to finish...',color=(-1,-1,-1), wrapWidth = 800) 
get_ready = visual.TextStim(mywin, text='Press any key to start...',color=(1,0,0),wrapWidth = 800) 

navigation = ["png/navigation1","png/navigation2.png","png/navigation3.png","png/navigation4.png",
              "png/navigation5.png","png/navigation6.png","png/navigation7.png","png/navigation8.png","png/navigation9.png",
              "png/navigation10.png","png/navigation11.png","png/navigation12.png"]
navigation_error = ["png/navigation1_error.png","png/navigation2_error.png","png/navigation3_error.png","png/navigation4_error.png",
              "png/navigation5_error.png","png/navigation6_error.png","png/navigation7_error.png","png/navigation8_error.png","png/navigation9_error.png",
              "png/navigation10_error.png","png/navigation11_error.png","png/navigation12_error.png"]
path = ["left", "left", "left", "left", "left", "down", "down", "down", "down", "down", "right"]

# set preferences
channel = "1" # preferred tv channel
min_time = 30 # min time on tv channel
call = "3" # person to communicate with

# determine error scores (in secs, will be added to the total time)
cost_navigation_error = 15
cost_tv_error = 5
cost_communicate_error = 15
cost_sos_error = 60

# memory variables
total_errors = 0
total_time = 0
error_navigation = 0
time_navigation = 0
error_tv = 0
time_tv = 0
error_communicate = 0
time_communicate = 0
error_sos = 0
time_sos = 0

# ************** Start run sentences **************
done = False
bufhelp.sendEvent('experiment','start')
keys = []
timer = core.Clock()
while done is False:
    if 'escape' in keys:
        keys = []
        done = True
        mywin.close() # quit
        core.quit()
    elif '1' in keys:
        keys = []
        [navigation_time,error_navigation,error_sos_update,sos_time] = navigate(path,navigation,navigation_error,get_ready,True)
        error_sos = error_sos + error_sos_update
        time_sos = time_sos+sos_time + (error_sos_update*cost_sos_error)
        time_navigation = navigation_time + (error_navigation*cost_navigation_error)-sos_time 
    elif '2' in keys:
        keys = []
        [tv_time,error_tv,error_sos_update,sos_time] = watch_tv(channel,min_time,get_ready,False)
        error_sos = error_sos + error_sos_update
        time_sos = time_sos+sos_time+ (error_sos_update*cost_sos_error)
        time_tv = tv_time + (error_tv*cost_tv_error) -sos_time
    elif '3' in keys:
        keys = []
        current_image = visual.ImageStim(mywin, "png/toilet.png") # set image
        [sos_time,error_sos_update] = sos_button(get_ready,current_image)
        error_sos = error_sos + error_sos_update
        time_sos = time_sos+sos_time+(error_sos_update*cost_sos_error)
    elif '4' in keys:
        keys = []
        [communicate_time,error_communicate,error_sos_update,sos_time] = communicate(call,get_ready,True)
        error_sos = error_sos + error_sos_update
        time_sos = time_sos+sos_time+(error_sos_update*cost_sos_error)
        time_communicate = communicate_time+ (error_communicate*cost_communicate_error) -sos_time
    elif '5' in keys:
        keys = []
        total_errors = 0
        total_time = 0
        error_navigation = 0
        time_navigation = 0
        error_sos = 0
        time_sos = 0
        error_tv = 0
        time_tv = 0
        error_communicate = 0
        time_communicate = 0
        [navigation_time,error_navigation,error_sos_update,sos_time] = navigate(path,navigation,navigation_error,get_ready,False)
        time_navigation = navigation_time + (error_navigation*cost_navigation_error)
        [tv_time,error_tv,error_sos_update,sos_time] = watch_tv(channel,min_time,get_ready,True)
        error_sos = error_sos + error_sos_update
        time_sos = time_sos+sos_time+(error_sos_update*cost_sos_error)
        time_tv = tv_time+ (error_tv*cost_tv_error)-sos_time
        [communicate_time,error_communicate,error_sos_update,sos_time] = communicate(call,get_ready,False)
        time_communicate = communicate_time + (error_communicate*cost_communicate_error)
        total_errors = total_errors + error_communicate + error_sos + error_navigation + error_tv
        total_time = total_time + time_communicate + sos_time + time_navigation + time_tv
    else:
        keys = []
        
        score_text = "\ntotal time: " + str(round(total_time/60,2)) + "min"
        
        main_screen = visual.TextStim(mywin, text='Select task: \n\n(1) navigate (time: ' + str(round(time_navigation)) + 'sec, errors: ' + str(error_navigation) +')' +
                                            '\n(2) tv (time: ' + str(round(time_tv)) + 'sec, errors: ' + str(error_tv) +')' + 
                                            '\n(3) sos (time: ' + str(round(time_sos)) + 'sec, errors: ' + str(error_sos) +')' + 
                                            '\n(4) communicate (time: ' + str(round(time_communicate)) + 'sec, errors: ' + str(error_communicate) +')' + 
                                            '\n\n(5) demo run '+ score_text +
                                            '\n\nPress Esc to stop',color=(-1,-1,-1),wrapWidth = 800) 
        
        showText(main_screen)
        keys = waitForKeypress()

showText(goodbye)
bufhelp.sendEvent('experiment','end')
waitForKeypress()
