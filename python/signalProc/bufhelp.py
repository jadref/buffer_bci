import sys, os
import collections
sys.path.append(os.path.dirname(__file__) + "/../../dataAcq/buffer/python")
import FieldTrip
import time
from math import ceil
import socket

MAXEVENTHISTORY=50

def askaddress():
    port=1972
    adress = eval(input("Buffer adress (default is \"localhost:1972\"):"))    
    if adress == "":
        adress = "localhost"
    else:
        try:
            split = adress.split(":")
            adress = split[0]
            port = int(split(1))
        except ValueError:
            print(("Invalid port formatting " + split[1]))
        except IndexError:
            print(("Invalid adress formatting " + adress))
    return (address,port)
    
def connect(address="localhost", port=1972, header=True, verbose = True):
    """Connects to the buffer at given address. And waits for a header (unless otherwise
    specified). The ftc variable contains the client connection."""
    
    global ftc
    ftc = FieldTrip.Client()
    while not ftc.isConnected:
        try:
            ftc.connect(address, port)
        except socket.error:
            print(("Failed to connect at " + address + ":" + str(port)))
            time.sleep(1)
                   
    if header:
        global hdr
        hdr = waitforheader(verbose)
        return ftc,hdr
    
    return ftc

def waitforheader(verbose = True):
    """Waits for a header to be added to the buffer."""
    global fSample, nSamples, lastupdate, hdr
    
    hdr = ftc.getHeader()
    while hdr is None:
        if verbose:
            print("Waiting for header")
        time.sleep(1)
        hdr = ftc.getHeader()
        
    nSamples = hdr.nSamples
    fSample = hdr.fSample
    lastupdate = time.time()
    
    return hdr
        
# function to send events to data buffer
# use as: sendEvent("markername", markernumber, offset)
def sendEvent(event_type, event_value, offset=0):
    global ftc
    e = FieldTrip.Event()
    e.type = event_type
    e.value = event_value
    if offset>0 : 
        sample, bla = ftc.poll()
        e.sample = sample + offset + 1
    ftc.putEvents(e)

globalstate=None
def buffer_newevents(evttype=None,timeout_ms=500,state=True,verbose=False):
    '''
    Wait for and return any new events recieved from the buffer between
    calls to this function
    
    timeout    = maximum time to wait in milliseconds before returning
    state      = internal state recording events processed so far
                 use state=None to reset all history
                 use state=True to use a single shared global state over all calls

    Output:
      events - [list] of matching events if using the global state
        OR
      (events,state) - [tuple] with list of matching events, and updated internal state for later calls
    '''
    global ftc,globalstate # use to store number events processed accross function calls
    useglobal=False
    if state is None :
        state = ftc.poll();
    elif state==True : # use single global state
        useglobal=True
        if globalstate is None:
            globalstate = ftc.poll();
        state = globalstate

    if verbose:
        print(("Waiting for event(s) " + str(evttype) + " with timeout_ms " + str(timeout_ms)))

    start = time.time()
    elapsed_ms = -1 # ensure checks at least once even with 0-timeout
    nSamples= state[0]
    nEvents = state[1]
    events=[]
    while len(events)==0 and elapsed_ms<timeout_ms:
        nSamples,curEvents=ftc.wait(-1,nEvents, int(timeout_ms - elapsed_ms))
        if curEvents>nEvents:
            if nEvents<curEvents-MAXEVENTHISTORY:
                print("Warning: long delay means missed events")
                nEvents = curEvents-MAXEVENTHISTORY
            events = ftc.getEvents([nEvents,curEvents-1])
            if not evttype is None and not events is None:
                events = [x for x in events if x.type in evttype]
        nEvents = curEvents # update starting number events (allow for buffer restarts)
        elapsed_ms = (time.time() - start)*1000

    # update record of which events we have processed so far
    state=(nSamples,nEvents)
    globalstate=state

    if useglobal: # return just the events
        return events
    else: # return events plus internal tracking state
        return (events,state)


def sendEventAuto(type, value, duration = 0, sample=-1, offset=-1, verbose = True):
    """Sends an event to the buffer with type type and value value. Unless 
    otherwise specified duration will be 0. Sample and offset will be estimated
    based on the global variables (unless specified)."""
    
    global ftc, fSample, nSample, lastUpdate, event
    event.type = type
    event.value = value
    event.duration = duration
    if sample == -1 or offset == -1:
        diffSamples = (time.time() - lastupdate) * fSample
        if sample == -1:
            event.sample = int(nSamples + diffSamples)
        if offset == -1:
            event.offset = ((diffSamples - int(diffSamples)) / fSample) * 1000.0
    
    if verbose:
        print("Sending event:")
        print(event)
    
    ftc.putEvents(event)

def update(verbose = True):
    """Requests a poll of the buffer and updates the global variables used by 
    sendevent to estimate the current nSamples."""
    
    (nsamp,nevent) = ftc.poll()
    global nSamples, lastupdate, nEvents
    nSamples = nsamp
    nEvents  = nevent
    lastupdate = time.time()
    if verbose:
        print(("Updated. nSamples = " + str(nSamples) + " at lastupdate " + str(lastupdate)))
    return (nsamp,nevent)

def waitforevent(trigger, timeout=1000,verbose = True):
    """Function that blocks until a certain event is sent. Trigger defines what
    event the function is waiting for based on createeventfilter
                
     If multiple events trigger satisfy the conditions (could happen if
     multiple events are sent to the buffer at the same time) they all will be
     returned."""    
      
    func = createeventfilter(trigger)

    global ftc
    start = time.time()
    nSamples, nEvents = ftc.poll()
    elapsed = time.time()*1000 - start*1000
    
    if verbose:
        print(("Waiting for event " + str(trigger) + " with timeout " + str(timeout)))
    
    while elapsed < timeout:
        nSamples, nEvents2 = ftc.wait(-1,nEvents, timeout - elapsed)     
        
        if nEvents < nEvents2:
            if nEvents<nEvents2-MAXEVENTHISTORY:
                print("Warning: long delay means missed events")
                nEvents = nEvents2-MAXEVENTHISTORY
            evts=ftc.getEvents((nEvents, nEvents2-1))
            print ( "Processing events:" + str(evts[0]))
            e = func(evts)
            print(str(len(e))+" events left")
    
            if len(e) == 1:
                return e[0]
            elif len(e) > 1:
                return e
        
        elapsed = time.time()*1000 - start*1000
        nEvents = nEvents2
            
    return None
    
def createeventfilter(trigger):
    """Creates a filter that filters out events that do not satisfies
    the trigger conditions, conditions depend on the type of the trigger 
    argument:
    
     function - trigger(e) equals true
     string   - e.type equals trigger
     tuple    - e.type equals trigger[0] and e.value equals trigger[1]
     list of  - e.type equals an element in trigger
      strings
     list of  - (e.type, e.value) equals an element in trigger
     dict     - e.type is a key in trigger and ( e.value equals an element in
                trigger[e.type] or trigger[e.type] is empty )
                
    Returns a function."""
                
    if isinstance(trigger, collections.Callable):
        if isinstance(trigger(e[0]),bool):
            func = lambda events: list(filter(trigger,events))
        else:
            raise Exception("Bad trigger, function should return a bool.")
    elif isinstance(trigger,str):
        func = lambda events: [x for x in events if trigger == x.type]
    elif isinstance(trigger, tuple):
        if len(trigger) == 2:
            if isinstance(trigger[0],str):
                func = lambda events: [x for x in events if trigger[0] == x.type and trigger[1] == x.value]
            else:
                raise Exception("Bad trigger, frist element in tuple should be a string.")
        else:
            raise Exception("Bad trigger, tuple should be length 2.")
    elif isinstance(trigger, list):
        if not trigger:
            raise Exception("Bad trigger, list should not be empty.")
        if all([isinstance(x, str) for x in trigger]):
            func = lambda events: [x for x in events if any([x.type == y for y in trigger])]
        elif all([isinstance(x, tuple) for x in trigger]):
            if all([len(x) == 2 for x in trigger]):
                if all([isinstance(x[0],str) for x in trigger]):
                    func = lambda events: [x for x in events if any([x.type == y[0] and x.value == y[1] for y in trigger])]
                else:
                    raise Exception("Bad trigger, frist element in tuple in list should be a string.")
            else:
                raise Exception("Bad trigger, tuples in list should be length 2.")
        else:
            raise Exception("Bad trigger, list should contain tuples or strings.")            
    elif isinstance(trigger, dict):
        if all([isinstance(x, str) for x in list(trigger.keys())]):
            if all([isinstance(x,list) for x in list(trigger.values())]):            
                func1 = lambda events: [x for x in events if any([x.type == y for y in list(trigger.keys())])]
                func2 = lambda events: [x for x in events if any([x.value == y for y in trigger[x.type]]) or not trigger[x.type]]
                func = lambda events: func2(func1(events))
            else:
                raise Exception("Bad trigger, values should be lists")
        else:
            raise Exception("Bad trigger, keys should be strings.")
    else:
        raise Exception("Bad trigger, should be a function, string, tuple, list of strings, list of tuples or a dict.")
        
    return func
    
def gatherdata(trigger, time, stoptrigger, milliseconds=False, verbose = True):
    """Gathers data and returns a list of data and triggering events. The
    arguments trigger and stroptrigger are used to create event filters (using
    the function createeventfilter). 
    
    Events that pass the trigger filter they are used as starting points for 
    data gathering (the sample field of the event to be exact). How many sample 
    are gathered from that point is determined by the time argument. If time is 
    a number (int or float) it will simply gather that number of samples. If 
    time is a dict, it will use the type of the trigger event as a key to look 
    up the number of samples that need to be gathered in the dict.
    
    If an event passes the stopfilter the data gathering will stop handling
    new trigger events and return the data as soon as the remaining samples
    are gathered.
    
    If the argument milliseconds is true, it is assumed that the numbers in the 
    time argument express the number of samples that need to be gathered in 
    milliseconds rather than samples.
    
    Note that this function assumes that at least half a second of data is
    being stored in the buffer.

    Outputs:
     data       - [[nSamp x nCh] x nEvent] list of lists of numpy-arrays of [nSamp x nCh] for each trigger
     events     - [event] list of trigger events
     stopevents - [event] list of events which caused us to stop gathering
"""

    global fSample
    
    if isinstance(time, dict):
        for key in list(time.keys()):
            if milliseconds:
                time[key] = int(ceil((time[key]/1000.0)*fSample))
            elif isinstance(time[key],float):
                time[key] = int(ceil(time[key])) 
    else:
        if milliseconds:
            time = ceil((time/1000.0)*fSample)    
        elif isinstance(time,float):
            time = int(ceil(time))    
    
    gatherFilter = createeventfilter(trigger)
    stopFilter = createeventfilter(stoptrigger)
    
    global ftc
    nSamples, nEvents = ftc.poll()
    

    stillgathering = True;
    gather = []
    events = []
    data = []
    
    while True:
        nSamples, nEvents2 = ftc.wait(-1,nEvents, 500)    
        
        if nEvents != nEvents2:
            e = ftc.getEvents((nEvents, nEvents2 -1))
            nEvents = nEvents2            

            stopevents = stopFilter(e)            
            
            if stopevents:
                stillgathering = False
                if len(stopevents) == 1:
                    stopevents = stopevents[0]
                
            e = gatherFilter(e)
            
            for event in e:
                if not isinstance(time,dict):
                    endSample = event.sample + time
                else:
                    endSample = event.sample + time[event.type]
                
                gather.append((event, endSample))
                
        for point in gather:
            event,endSample = point
            if nSamples > endSample:
                events.append(event)
                data.append(ftc.getData((event.sample, endSample -1))) # [ nSamples x nChannels ]
                gather.remove(point)            
                if verbose:
                    print(("Gathering " + str(event.type) + " " + str(event.value) + " data from " + str(event.sample) + " to " +str(endSample)))
                
        if not stillgathering and not gather:
            break
            
    return (data,events, stopevents)
