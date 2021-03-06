import sys, os
import collections
sys.path.append(os.path.dirname(__file__) + "/../../dataAcq/buffer/python")
import FieldTrip
import time
from math import ceil
import socket
import numpy as np
    
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
    if state==True : # use a single global state
        useglobal=True
        if globalstate is None:
            globalstate = ftc.poll()
        state = globalstate
    else : 
        if not state : # init if not already set
            state = ftc.poll()

    if verbose:
        print("Waiting for event(s) " + str(evttype) + " with timeout_ms " + str(timeout_ms) + "from: (" + str(state[0])+","+str(state[1]) + ")")
        if useglobal : print("using global state")

    start = time.time()
    elapsed_ms = -1 # ensure checks at least once even with 0-timeout
    nSamples= state[0]
    nEvents = state[1]
    events=[]
    while len(events)==0 and elapsed_ms<timeout_ms:
        # N.B. this may return no matching events, hence keep waiting.
        nSamples,curEvents=ftc.wait(-1,nEvents, int(timeout_ms - elapsed_ms))
        if curEvents>nEvents:
            try: # guard against old events dropped from the buffer
                events = ftc.getEvents([nEvents,curEvents-1])
            except:
                print("Warning: long delay means missed events")
                nEvents= curEvents-MAXEVENTHISTORY
                events = ftc.getEvents([nEvents,curEvents-1])
            
            if not evttype is None and not events is None:
                events = [x for x in events if x.type in evttype]
            if events : print("Got %d events"%(len(events)))
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
    
def gatherdata(trigger, time, stoptrigger=[], pending=[], state=True, stopondata=False, milliseconds=False, verbose = True):
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
    
    Inputs: 
     trigger    - [] set of triggers to start recording data
     time       - [] length of data to record, in samples if Milliseconds=False, in milliseconds if Milliseconds=true
     stoptrigger- [] set of triggers to stop gathering data.  
                     **return immeadiately data is available if stoptrigger is *not* set**
     pending    - [] set of previously identified events to get data from who do not have all the data yet
     
     stopondata - [boolean] if set then stop gathering as soon as we have some data to return, i.e. trigger-event happened and sufficient samples available.
    Outputs:
     data       - [[nSamp x nCh] x nEvent] list of lists of numpy-arrays of [nSamp x nCh] for each trigger
     events     - [event] list of trigger events
     stopevents - [event] list of events which caused us to stop gathering
     pending      - [struct] internal state of this function to track pending events which have not got complete data yet
     state      - internal state recording events processed so far        (True=global-state)
                   use state=None to reset all history, i.e. ignore any events/samples before the current time
                   use state=True to use a single shared global state over all calls
    Example Usage:
      # gather data for trigger events, and return when 'stimulus.end' event is recieved
      data,devents,stopevents=bufhelp.gatherdata('stimulus.epoch',100,'stimulus.end)

      # wait for trigger event and return data as soon as it's ready 
      pending=[]
      while true:
         data,devents,stopevents,pending=bufhelp.gatherdata('stimulus.epoch',100,[],pending,stopondata=true)
         print('Got %d new events'%(len(data),len(devents)))

      # wait for trigger event and return data OR when "stimulus.end"
      pending=[]
      while true:
         data,devents,stopevents,pending=bufhelp.gatherdata('stimulus.epoch',100,'stimulus.end',pending,stopondata=true)
         print('Got %d new events'%(len(data),len(devents)))
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
    if stoptrigger :        
        stopFilter = createeventfilter(stoptrigger)
    else:
        if verbose: print("Stopping when data available")
        stopondata=True
        
    global ftc
    global globalstate # cursor for how much data processed in previous calls 
    useglobal=False
    if state==True : # use a single global state
        useglobal=True
        if globalstate is None:
            globalstate = ftc.poll()
        state = globalstate
    else : 
        if not state : # init if not already set
            state = ftc.poll()
    nSamples=state[0]
    nEvents =state[1]
            
    stillgathering = True;
    events = []
    data = []
    stopevents=[]
    
    while True:
        nSamples, nEvents2 = ftc.wait(-1,nEvents, 500)    
        
        if nEvents != nEvents2:
            e = ftc.getEvents((nEvents, nEvents2 -1))
            nEvents = nEvents2            

            if stoptrigger :
                stopevents = stopFilter(e)            
            
                if stopevents:
                    stillgathering = False                
                
            e = gatherFilter(e)
            
            for event in e:
                if verbose:
                    print("Recording event:"+str(event))
                if not isinstance(time,dict):
                    endSample = event.sample + time
                else:
                    endSample = event.sample + time[event.type]
                
                pending.append((event, endSample))
                
        for point in pending:
            event,endSample = point
            if nSamples > endSample:
                events.append(event)
                data.append(ftc.getData((event.sample, endSample -1))) # [ nSamples x nChannels ]
                pending.remove(point)            
                if stopondata : # stop gathering if should return first time data is available
                    stillgathering = False
                if verbose:
                    print(("Saving event :" + str(event) + " data from " + str(event.sample) + " to " +str(endSample)))
                
        if not stillgathering:
            break
            
    # update record of which events we have processed so far
    state=(nSamples,nEvents)
    globalstate=state

    return (data, events, stopevents, pending)



def read_buffer_offline_events(file,verbosity=0):
    '''read all events from a ft_offline event save file'''
    if isinstance(file,str) :
        file = open(file,'rb')
    # read the entier file in one go into bytes
    buf = file.read()
    # scan through buf reading the events
    offset = 0
    E = []
    while 1:
        e = FieldTrip.Event()
        consumed = e.deserialize(buf[offset:])
        if consumed == 0:
            break
        E.append(e)
        offset = offset + consumed
    if verbosity>0 : print("Read %d events"%(len(E)))
    return E

def read_buffer_offline_data(file,hdr=None,datype=None,nchans=None,verbosity=0):
    '''read all data from a ft_offline event sample file'''
    if isinstance(file,str) :
        file = open(file,'rb')
    # read the entier file in one go into bytes
    buf = file.read()
    fsize=len(buf)
    # use hdr object to get info about the data type
    if hdr :
        if not nchans : nchans = hdr.nChannels
        if not datype : datype = hdr.dataType
    if not datype : print("Error: didn't give header or datatype")
    if not nchans : print("Error: didn't give header or nchans")
    nsamp = int(len(buf) / nchans / FieldTrip.wordSize[datype])
    D = FieldTrip.rawtoarray((nsamp, nchans), datype, buf)
    if verbosity>0 : print("Read %d samples"%(len(D)))
    return D

def read_buffer_offline_header(file,verbosity=0):
    '''read header information from a ft_offline binary header save file'''
    import struct
    if isinstance(file,str) :
        file = open(file,'rb')
    # read the entier file in one go into bytes
    buf = file.read()
    (nchans, nsamp, nevt, fsamp, dtype, bfsiz) = struct.unpack('IIIfII', buf[0:24])
    H = FieldTrip.Header()
    H.nChannels = nchans
    H.nSamples = nsamp
    H.nEvents = nevt
    H.fSample = fsamp
    H.dataType = dtype
    # read the channel names
    bufsize=len(buf)
    if bufsize > 0:
        offset = 24
        while offset + 8 < bufsize:
            (chunk_type, chunk_len) = struct.unpack('II', buf[offset:offset+8])
            offset+=8
            if offset + chunk_len < bufsize:
                break
            H.chunks[chunk_type] = buf[offset:offset+chunk_len]
            offset += chunk_len

        if FieldTrip.CHUNK_CHANNEL_NAMES in H.chunks:
            labels = H.chunks[FieldTrip.CHUNK_CHANNEL_NAMES].decode() #convert from byte->char
            L = labels.split('\0')
            numLab = len(L);
            if numLab>=H.nChannels:
                H.labels = L[0:H.nChannels]
    return H

def sliceraw(alldata,events,trigger,time,hdr=None,fSample=None,offset=None,verbose=True):
    ''' slice out epochs based on trigger events from buffer stream

    Input:
      alldata- [nSample x nCh] all data in the file
      events - [nEvt x 1] Event objects
      trigger- 'type' OR ('type','value') or ['type1','type2',...'typen'] trigger condition 
               in formate used by `createventfilter` to identify which events to slice on
      time   - [float] duration of the slice relative to the event in seconds
      offset - [bgnoffset,endoffset] shift in slice start/end relative to [0,time]
      hdr    - data header object
      fSample- data sample rate
    Output:
      data  - [nTrl,nSample,nCh] sliced data
      devents-[nTrlx1] Event objects
    
    Example:
      # load the example-data and slice on the tgtFlash event
      datadir='../../matlab/offline/example_data/raw_buffer/0001'
      hdr    =bufhelp.read_buffer_offline_header(datadir+'/header')
      alldata =bufhelp.read_buffer_offline_data(datadir+'/samples',hdr=hdr)
      events =bufhelp.read_buffer_offline_events(datadir+'/events')
      data,devents = bufhelp.sliceraw(alldata,events,"stimulus.tgtFlash",.6,hdr=hdr)
      # get labels and train a classifier
      y,ydict=bufhelp.eventvalue2label(devents)
      import sklearn.linear_model
      clsfr=sklearn.linear_model.RidgeCV(store_cv_values=True)
      clsfr.fit(np.reshape(data,(data.shape[0],-1),y) # fit, after -> [ nTrl x nFeat ]
      print("MSSE=%g"%np.mean(clsfr.cv_values_))
    '''
    # Compute the start-end of the epoch relative to the event time
    bgnend = [0,time]    
    if offset :  bgnend=bgnend + offset # include offset if given
    # convert to samples
    if not fSample and hdr : fSample=hdr.fSample 
    bgnend = [ int(b * fSample) for b in bgnend ] 
    # identify trigger events
    gatherFilter = createeventfilter(trigger)
    triggerevents = gatherFilter(events)
    if len(triggerevents)==0 :
        print("Warning: trigger didn't match any events!")
        return (None,None)
    if verbose : print("Slicing %d trigger events:"%(len(triggerevents)),end='')
    # grab the slices
    data=[]
    devents=[]
    printi=0
    for ei,evt in enumerate(triggerevents):
        rng = [evt.sample + b for b in bgnend ]
        if rng[0]<0 or rng[1]>len(alldata):
            print("Skipping event %d [%d-%d] outside available data [0-%d]"%(ei,rng[0],rng[1],len(alldata)))
            continue;
        data.append(alldata[rng[0]:rng[1]])
        devents.append(evt)
        # progress bar
        if verbose and ei>printi: print('.',end=''); printi=printi+int(len(triggerevents)/100)
    if verbose : print('') # newline
    if isinstance(alldata,np.ndarray): # convert to 3-d numpy array
        data = np.array(data)
    return (data,devents)


def eventvalue2label(events):
    '''convert the values in the given set of events into a unique set of 
       class IDs and return the mapped values and the value-dictionary
       
       Example:
         y,ydict=bufhelp.eventvalue2label(events)
    '''
    # 0: get class labels from events values
    y = [e.value[0] for e in events] 
    # convert to numeric labels
    valuedict={} # dict to convert from event.values to numbers    
    #y = np.array(y) # N.B. Only works with *NUMERIC* event values...
    # get the unique values in y
    valuedict = set(y)
    # convert to dictionary
    valuedict = { val:i for i,val in enumerate(valuedict) }
    # use the dict to map from values to numbers
    y    = np.array([ valuedict[val] for val in y ])
    return (y,valuedict)


if __name__ == "__main__":
    # small demo of running and offline classification analysis for testing
    # load the example-data and slice on the tgtFlash event
    datadir='../../matlab/offline/example_data/raw_buffer/0001'
    hdr    =bufhelp.read_buffer_offline_header(datadir+'/header')
    alldata =bufhelp.read_buffer_offline_data(datadir+'/samples',hdr=hdr)
    events =bufhelp.read_buffer_offline_events(datadir+'/events')
    data,devents = bufhelp.sliceraw(alldata,events,"stimulus.tgtFlash",.6,hdr=hdr)
    # get labels and train a classifier
    y,ydict=bufhelp.eventvalue2label(devents)
    import sklearn.linear_model
    print("Ridge Regression:")
    clsfr=sklearn.linear_model.RidgeClassifierCV(store_cv_values=True) # ridge-regression
    clsfr.fit(np.reshape(data,(data.shape[0],-1)),y) # fit, after -> [ nTrl x nFeat ]
    print("MSSE=%g"%np.min(np.mean(clsfr.cv_values_,axis=0)))
    print("Logistic Regression:")
    clsfr=sklearn.linear_model.LogisticRegressionCV() # logistic-regression
    clsfr.fit(np.reshape(data,(data.shape[0],-1)),y) # fit, after -> [ nTrl x nFeat ]
    print("Best training score=%g"%np.max(np.mean(clsfr.scores_[1],axis=0)))    
    
