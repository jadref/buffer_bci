This directory contains sub-directories which contain example 'echo-clients' written in different programming languages.

All these clients, listen for incomming events and then:
 * if the event.type == 'exit' then stop echoing
 * if the event.type == 'echo' they ignore the event
 * otherwise they re-send the event (i.e. echo it) with the new type = 'echo'

The languages used are:
csharpclient = C#
pythonclient = Python
matlabclient = Matlab/Octave
cclient      = (iso)-C
