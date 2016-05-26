bufferpath = "../../python/signalProc"

import os, sys, random, math, time, socket, struct
sys.path.append(os.path.dirname(__file__)+bufferpath)
import bufhelp

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
	print("Send cmd " + str(command) )
	cmd = (br_player * 10) + command
	data = struct.pack('B', cmd)
	
	br_socket.sendto(data, (br_hostname, br_port))
	
#Connect to BrainRacers
br_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM);

#Connect to Buffer
(ftc,hdr) = bufhelp.connect(buffer_hostname,buffer_port)
print("Connected to " + buffer_hostname + ":" + str(buffer_port))
print(hdr)

# Receive events from the buffer and process them.
def processBufferEvents():
	global running
	events = bufhelp.buffer_newevents()

	for evt in events:
		print(str(evt.sample) + ": " + str(evt))

		if evt.type == 'classifier.prediction':
			pred = evt.value
			if pred[0] > PRED_IDX_1_THRESHOLD: send_command(PRED_IDX_1_CMD)
			if pred[1] > PRED_IDX_2_THRESHOLD: send_command(PRED_IDX_2_CMD)
			if pred[2] > PRED_IDX_3_THRESHOLD: send_command(PRED_IDX_3_CMD)

		elif evt.type == 'keyboard':
	                if   evt.value == 'q' :  send_command(PRED_IDX_1_CMD)
                        elif evt.value == 'w' :  send_command(PRED_IDX_2_CMD)
                        elif evt.value == 'e' :  send_command(PRED_IDX_3_CMD)
                        elif evt.value == 'esc': running=false

		elif evt.type == 'startPhase.cmd':
			if evt.value == 'quit':
				running = False


# Receive events until we stop.	
running = True
while running:
	processBufferEvents()

