#!/usr/bin/env python3
bufferpath = "../../python/signalProc"

import os, sys, random, math, time, socket, struct
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),bufferpath))
import bufhelp

# Configuration of buffer
buffer_hostname='localhost'
buffer_port=1972

# Configuration of BrainRacer
br_hostname='localhost'
br_port=5555
br_player=1

# Command offsets, do not change.
CMD_SPEED= 1
CMD_JUMP = 2
CMD_ROLL = 3
CMD_RST  = 99

# Command configuration
CMDS      = [CMD_ROLL, CMD_RST, CMD_JUMP, CMD_SPEED]
THRESHOLDS= [.1,        .1,       .1,     .1      ]

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


def max2(numbers):
    i1 = i2 = None
    m1 = m2 = float('-inf')
    for i,v in enumerate(numbers):
        if v > m2:
            if v >= m1:
                m1, m2 = v, m1
                i1, i2 = i, i1
            else:
                m2 = v
                i2 = i
    return ([m1,m2],[i1,i2])

# Receive events from the buffer and process them.
def processBufferEvents():
        global running
        events = bufhelp.buffer_newevents()

        for evt in events:
                print(str(evt.sample) + ": " + str(evt))

                if evt.type == 'classifier.prediction':
                        pred = evt.value
                        (m12,i12) = max2(pred) # find max value
                        if m12[0]-m12[1] > THRESHOLDS[i12[0]] : send_command(CMDS[i12[0]]); # if above threshold send

                elif evt.type == 'keyboard':
                        if   evt.value == 'q' :  send_command(CMD_SPEED)
                        elif evt.value == 'w' :  send_command(CMD_JUMP)
                        elif evt.value == 'e' :  send_command(CMD_ROLL)
                        elif evt.value == 'esc': running=false

                elif evt.type == 'startPhase.cmd':
                        if evt.value == 'quit':
                                running = False


# Receive events until we stop. 
running = True
while running:
        processBufferEvents()

