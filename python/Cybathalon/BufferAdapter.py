bufferpath = "../../dataAcq/buffer/python"

import os, sys, random, math, time, socket
sys.path.append(os.path.dirname(__file__)+bufferpath)
import FieldTrip

# Configuration of buffer
buffer_hostname='localhost'
buffer_port=1972

# Configuration of BrainRacer
br_hostname='localhost'
br_port=5555
br_player=1

# Command offsets, do not change.
CMD_SPEED = 1
CMD_JUMP = 2
CMD_ROLL = 3

# Command configuration
PRED_IDX_1_CMD = CMD_SPEED
PRED_IDX_2_CMD = CMD_JUMP
PRED_IDX_3_CMD = CMD_ROLL

PRED_IDX_1_THRESHOLD = 0
PRED_IDX_2_THRESHOLD = 0
PRED_IDX_3_THRESHOLD = 0

# Sends a command to BrainRacer.
def send_command(command):
	global br_socket
	
	cmd = (br_player * 10) + command
	data = struct.pack('B', cmd)
	
	br_socket.sendto(data, (br_hostname, br_port))
	
	
#Connect to BrainRacers
br_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM);

#Connect to Buffer
ftc = FieldTrip.Client()

# Wait until the buffer connects correctly and returns a valid header
hdr = None;
while hdr is None :
    print('Trying to connect to buffer on %s:%i ...'%(buffer_hostname,buffer_port))
    try:
        ftc.connect(buffer_hostname, buffer_port)
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

def buffer_newevents(evttype=None,timeout_ms=500,verbose=False):
    '''
    Wait for and return any new events recieved from the buffer between
    calls to this function
    
    timeout    = maximum time to wait in milliseconds before returning
    '''
    global ftc,nEvents # use to store number events processed accross function calls
    if not 'nEvents' in globals(): # first time initialize to events up to now
    	start, nEvents = ftc.poll()

    if verbose:
        print("Waiting for event(s) " + str(evtypes) + " with timeout_ms " + str(timeout_ms))

    start = time.time()
    elapsed_ms = 0
    events=[]
    while len(events)==0 and elapsed_ms<timeout_ms:
        nSamples,curEvents=ftc.wait(-1,nEvents, int(timeout_ms - elapsed_ms))
        if curEvents>nEvents:            
            events = ftc.getEvents([nEvents,curEvents-1])            
            if not evttype is None:
                events = filter(lambda x: x.type in evttype, events)
        nEvents = curEvents # update starting number events (allow for buffer restarts)
        elapsed_ms = (time.time() - start)*1000        
    return events



# Receive events from the buffer and process them.
def processBufferEvents():
	global running
	events = buffer_newevents()

	for evt in events:
		print(str(evt.sample) + ": " + str(evt))

		if evt.type == 'classifier.prediction':
			pred = evt.value
			if pred[0] > PRED_IDX_1_THRESHOLD: send_command(PRED_IDX_1_CMD)
			if pred[1] > PRED_IDX_2_THRESHOLD: send_command(PRED_IDX_2_CMD)
			if pred[2] > PRED_IDX_3_THRESHOLD: send_command(PRED_IDX_3_CMD)
			
		elif evt.type == 'startPhase.cmd':
			if evt.value == 'quit':
				running = False
				break


# Receive events until we stop.	
running = True
while running:
	processBufferEvents()
	
