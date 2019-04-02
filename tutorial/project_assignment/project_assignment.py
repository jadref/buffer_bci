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
    
    current_image = visual.ImageStim(mywin, image="png/navigation1.png") # set image
    current_image.draw()
    showText(get_ready)
    keys = waitForKeypress()
    
    mywin.flip()
    current_image.draw()
    mywin.flip()
    
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
                timer = core.Clock()
                timer.reset()
                error_sos = sos_button(get_ready,current_image)
                sos_time = timer.getTime()
                sos = False
    return [errors, error_sos, sos_time]

# browse tv channels. When all channels are seen once, the "preferref" channel is highlighted when visited for a second time.
# User needs to watch preferred channel for at least min_time. User can stop watching by sending tv.end event. 
# (listens to commands: tv.1, tv.2, tv.3 and tv.end)
def watch_tv(channel,min_time,get_ready,sos):
    errors = 0
    error_sos = 0
    sos_time = 0
    
    current_image = visual.ImageStim(mywin, image="png/tv.png") # set image
    current_image.draw()
    showText(get_ready)
    keys = waitForKeypress()
    
    mywin.flip()
    current_image.draw()
    mywin.flip()
    
    triggerevents=["tv"]
    stopevent=("tv","end")
    trlen_samp = 50
    state = []
    endTV = False
    current_idx = 0
    channels_seen = [False, False, False]
    timer = core.Clock()
    start_counting = False
    print("Waiting for triggers: %s and endtrigger: %s.%s"%(triggerevents[0],stopevent[0],stopevent[1]))
    while endTV is False:
        # grab data after every t:'stimulus' event until we get a {t:'stimulus.training' v:'end'} event 
        #data, events, stopevents, state = bufhelp.gatherdata(triggerevents,trlen_samp,stopevent, state, milliseconds=False)
        data, events, stopevents, state = bufhelp.gatherdata(triggerevents,trlen_samp,[], state, milliseconds=False)
        for ei in np.arange(len(events)-1,-1,-1):
            ev = events[ei]
            if ev.type == "tv":
                if ev.value == "1":
                    current_image = visual.ImageStim(mywin, "png/tv_nature.png") # set image
                    channels_seen[0] = True
                elif ev.value == "2":
                    current_image = visual.ImageStim(mywin, "png/tv_mes_op_tafel.png") # set image
                    channels_seen[1] = True
                    if sos:
                        sos_timer = core.Clock()
                        sos_timer.reset()
                        error_sos = sos_button(get_ready,current_image)
                        sos_time = sos_timer.getTime()
                        sos = False
                elif ev.value == "3":
                    current_image = visual.ImageStim(mywin, "png/tv_sesamstraat.png") # set image
                    channels_seen[2] = True
                current_image.draw()
                mywin.flip()
            if False not in channels_seen:
                if ev.value == channel:
                    if start_counting is False:
                        current_image = visual.ImageStim(mywin, "png/tv_done.png") # set image
                        current_image.draw()
                        mywin.flip()
                        start_counting = True
                        timer.reset() # start counting time
                elif ev.value == "end":
                    if timer.getTime >= min_time:
                        endTV = True
                else:
                    start_counting = False
                    errors = errors + 1
    return [errors,error_sos,sos_time]

# User needs help from a nurse to go to the bathroom, for pain treatment or for food/drinks. 
# First push SOS button, then indicate what help is needed.
def sos_button(get_ready,previous_image):
    errors = 0
    sos = ["png/sos_food.png", "png/sos_pain.png", "png/sos_toilet.png"]
    
    # choose random sos
    r = np.random.randint(len(sos))
    
    current_image = visual.ImageStim(mywin, image=sos[r]) # set image
    current_image.draw()
    showText(get_ready)
    keys = waitForKeypress()
    
    mywin.flip()
    current_image.draw()
    mywin.flip()
    
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
    return errors

# call someone: mom, Terry or Livia
def communicate(call,get_ready,sos):
    errors = 0
    error_sos = 0
    sos_time = 0
    
    current_image = visual.ImageStim(mywin, image="png/mobile.png") # set image
    current_image.draw()
    showText(get_ready)
    keys = waitForKeypress()
    
    mywin.flip()
    current_image.draw()
    mywin.flip()
    
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
                        timer = core.Clock()
                        timer.reset()
                        error_sos = sos_button(get_ready,current_image)
                        sos_time = timer.getTime()
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
    return [errors,error_sos,sos_time]

# Setup the stimulus window
screenWidth = 1300
screenHeight = 700 
mywin = visual.Window(size=(screenWidth, screenHeight), fullscr=False, screen=1, allowGUI=False, allowStencil=False,
    monitor='testMonitor', units="pix",color=[1,1,1], colorSpace='rgb',blendMode='avg', useFBO=True)

#create some stimuli
main_screen = visual.TextStim(mywin, text='Select task: \n\n(1) navigate \n(2) tv \n(3) toilet \n(4) communicate \n\nPress Esc to stop',color=(-1,-1,-1),wrapWidth = 800) 
goodbye = visual.TextStim(mywin, text='Bye! \n\nPress a key to finish...',color=(-1,-1,-1), wrapWidth = 800) 
get_ready = visual.TextStim(mywin, text='Press any key to start...',color=(1,0,0),wrapWidth = 800) 

navigation = ["png/navigation1","png/navigation2.png","png/navigation3.png","png/navigation4.png",
              "png/navigation5.png","png/navigation6.png","png/navigation7.png","png/navigation8.png","png/navigation9.png",
              "png/navigation10.png","png/navigation11.png","png/navigation12.png"]
navigation_error = ["png/navigation1_error.png","png/navigation2_error.png","png/navigation3_error.png","png/navigation4_error.png",
              "png/navigation5_error.png","png/navigation6_error.png","png/navigation7_error.png","png/navigation8_error.png","png/navigation9_error.png",
              "png/navigation10_error.png","png/navigation11_error.png","png/navigation12_error.png"]
path = ["left", "left", "left", "left", "left", "down", "down", "down", "down", "down", "right"]

channel = "1"
min_time = 30

call = "3"

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
        timer.reset()
        [error_navigation,error_sos_update,sos_time] = navigate(path,navigation,navigation_error,get_ready,True)
        error_sos = error_sos + error_sos_update
        time_sos = time_sos+sos_time
        time_navigation = timer.getTime()-sos_time
        total_errors = total_errors + error_navigation + error_sos_update
        total_time = total_time + time_navigation + sos_time
    elif '2' in keys:
        keys = []
        timer.reset()
        [error_tv,error_sos_update,sos_time] = watch_tv(channel,min_time,get_ready,True)
        error_sos = error_sos + error_sos_update
        time_sos = time_sos+sos_time
        time_tv = timer.getTime()-sos_time
        total_errors = total_errors + error_tv + error_sos_update
        total_time = total_time + time_tv + sos_time
        print("total time: " + str(total_time))
        print("total errors: " + str(total_errors))
    elif '3' in keys:
        keys = []
        timer.reset()
        current_image = visual.ImageStim(mywin, "png/toilet.png") # set image
        error_sos_update = sos_button(get_ready,current_image)
        error_sos = error_sos + error_sos_update
        time_sos = time_sos+timer.getTime()
        total_errors = total_errors + error_sos_update 
        total_time = total_time + time_sos 
        print("total time: " + str(total_time))
        print("total errors: " + str(total_errors))
    elif '4' in keys:
        keys = []
        timer.reset()
        [error_communicate,error_sos_update,sos_time] = communicate(call,get_ready,True)
        error_sos = error_sos + error_sos_update
        time_sos = time_sos+sos_time
        time_communicate = timer.getTime()-sos_time
        total_errors = total_errors + error_communicate + error_sos_update
        total_time = total_time + time_communicate + sos_time
        print("total time: " + str(total_time))
        print("total errors: " + str(total_errors))
    else:
        keys = []
        
        score_text = "\n\ntotal time: " + str(round(total_time/60,2)) + "min\ntotal errors: " + str(total_errors)
        
        main_screen = visual.TextStim(mywin, text='Select task: \n\n(1) navigate (time: ' + str(round(time_navigation)) + 'sec, errors: ' + str(error_navigation) +')' +
                                            '\n(2) tv (time: ' + str(round(time_tv)) + 'sec, errors: ' + str(error_tv) +')' + 
                                            '\n(3) sos (time: ' + str(round(time_sos)) + 'sec, errors: ' + str(error_sos) +')' + 
                                            '\n(4) communicate (time: ' + str(round(time_communicate)) + 'sec, errors: ' + str(error_communicate) +')' + 
                                            score_text +
                                            '\n\nPress Esc to stop',color=(-1,-1,-1),wrapWidth = 800) 
        
        showText(main_screen)
        keys = waitForKeypress()

showText(goodbye)
bufhelp.sendEvent('experiment','end')
waitForKeypress()
