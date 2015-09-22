# TODO :
#  [X] - load sequence from file
#  [] - use of the event sequence
#  [] - noise codes stimulus
from __future__ import division  # ensure the divisions produce float if needed
from random import shuffle, randint, random
from math import ceil, cos, sin, pi

class StimSeq :
    stimSeq     = None # [ nEvent x nSymb ] stimulus code for each time point for each stimulus
    stimTime_ms = None # time stim i ends, i.e. stimulus i is on screen from stimTime_ms[i-1]-stimTime_ms[i]
    eventSeq    = None # events to send at each stimulus point

    def __init__(self,st=None,ss=None,es=None):
        self.stimSeq     = ss
        self.stimTime_ms = st
        self.eventSeq    = es

    def __str__(self):
        res = "#stimTimes: ";
        if not self.stimTime_ms is None:
            res += "(1," + str(len(self.stimTime_ms)) + ")\n"
            for i in range(0,len(self.stimTime_ms)-1):
                res += str(self.stimTime_ms[i]) + " "
            res+= str(self.stimTime_ms[-1]) + "\n"
        else:
            res+= "<null>\n"
        res+= "\n\n"
        res += "#stimSeq : "
        if not self.stimSeq is None:
            res += "(" + str(len(self.stimSeq[0])) + "," + str(len(self.stimSeq)) + ")\n"
            for j in range(0,len(self.stimSeq[0])):
                for i in range(len(self.stimSeq)-1):
                    res += str(self.stimSeq[i][j]) + " "                
                res+= str(self.stimSeq[-1][j]) + "\n"
        else:
            res+= "<null>\n"
        res+="\n\n"
        return res

    @staticmethod
    def readArray(f,width=-1):
        array=[]
        nEmpty=0
        for line in f:
            line = line.strip();
            if len(line)==0 :
                nEmpty += 1
                if nEmpty>1 and len(array)>0 : break # double empty means end-of-array
                else: continue 
            elif line[0]=="#" : continue # comment line
            cols = line.split();
            if width<0 : width=len(line)
            elif width>0 and not len(cols) == width : 
                raise(Exception("Row widths are not consistent: "+ str(width) + "!=" + str(len(cols))))
            cols = [ float(c) for c in cols ] # convert string to numeric
            array.append(cols) # add to the stimSeq
        return array

    @staticmethod
    def fromString(fname):
        f=open(fname,'r') if type(fname) is str else fname
        st=StimSeq.readArray(f) # read the stim times
        if len(st)>1 : raise(Exception("Error: stimTime has multiple rows!"))
        else: st=st[0] # un-nest
        ss=StimSeq.readArray(f,len(st)) # read stim-seq - check same length
        # transpose ss to have time in the major dimension
        ss2=[[None]*len(ss)]*len(ss[0]);
        for s in range(len(ss)):
            for t in range(len(ss[s])):
                ss2[t][s]=ss[s][t]        
        return StimSeq(st,ss2)

    @staticmethod
    def mkStimSeqScan(nSymb, seqDuration, isi):
        nEvent = int(seqDuration/isi) + 1
        stimTime_ms = [ (ei+1)*1000.0*isi for ei in range(nEvent) ]
        stimSeq     = [[None]*nSymb for i in range(nEvent)]
        for ei in range(nEvent):
            stimSeq[ei][ei%nSymb]=1
        return StimSeq(stimTime_ms,stimSeq)
    
    @staticmethod        
    def mkStimSeqRand(nSymb, seqDuration, isi):
        perm = [i for i in range(nSymb)] # pre-alloc order for later shuffle
        nEvent = int(seqDuration/isi) + 1
        stimTime_ms = [ (ei+1)*1000.0*isi for ei in range(nEvent) ]
        stimSeq     = [[None]*nSymb for i in range(nEvent)]
        for ri in range(0,nEvent,nSymb):
            shuffle(perm)
            for ei in range(nSymb):
                if ri+ei < len(stimSeq): # don't go past the end 
                    stimSeq[ri+ei][perm[ei]]=1
        return StimSeq(stimTime_ms,stimSeq)

    @staticmethod
    def mkStimSeqOddball(nSymb, seqDuration, isi, tti=None, distractor=False):
        # TODO: [] add check to minimize cross-talk with other symbols
        nEvent = int(seqDuration/isi) + 1        
        tti_ev      = tti/isi if not tti is None else nSymb # ave num events between targets
        stimTime_ms = [ (ei+1)*1000.0*isi for ei in range(nEvent) ]
        stimSeq     = [[None]*nSymb for i in range(nEvent)]

        for ei in range(nSymb):
            si= 1+random()*tti_ev # last stimulus time
            for ri in range(0,nEvent):
                stimSeq[ri][ei] = 0
                if ri==int(si) :
                    stimSeq[ri][ei] = 1
                    si = si + tti_ev*(.5 + random()) # step [.5-1.5]*tti
        return StimSeq(stimTime_ms,stimSeq)
                

    @staticmethod
    def mkStimSeqNoise(nSymb, seqDuration, isi, weight=.5):
        nEvent = int(seqDuration/isi) + 1
        stimTime_ms = [ (ei+1)*1000.0*isi for ei in range(nEvent) ]
        stimSeq     = [[None]*nSymb for i in range(nEvent)]
        for ei in range(nEvent):
            for si in range(nSymb):
                if random() > weight :
                    stimSeq[ei][si]=1
        return StimSeq(stimTime_ms,stimSeq)

    @staticmethod
    def mkStimSeqSSEP(nSymb, seqDuration, isi, periods=None, smooth=False):
        # N.B. Periods is in *seconds*
        nEvent = int(seqDuration/isi) + 1
        stimTime_ms = [ (ei+1)*1000.0*isi for ei in range(nEvent) ]
        stimSeq     = [[None]*nSymb for i in range(nEvent)]        
        for si in range(nSymb):
            if not type(periods[si]) is list: # ensure periods has duration and phase
                periods[si] = [periods[si],0]
            for ei in range(nEvent):
                # N.B. include slight phase offset to prevent value being exactly==0
                stimSeq[ei][si]=cos((stimTime_ms[ei]/1000.0+.0001+periods[si][1])/periods[si][0]*2*pi);
                if smooth :
                    stimSeq[ei][si]=(stimSeq[ei][si]+1)/2; # ensure all positive values in range 0-1
                else:
                    stimSeq[ei][si]=1 if stimSeq[ei][si]>0 else 0
        return StimSeq(stimTime_ms,stimSeq)

    @staticmethod
    def mkStimSeqInterval(nSymb, seqDuration, isi, periods=None):
        # N.B. Periods is in *seconds*
        nEvent = int(seqDuration/isi) + 1
        stimTime_ms = [ (ei+1)*1000.0*isi for ei in range(nEvent) ]
        stimSeq     = [[None]*nSymb for i in range(nEvent)]        
        for si in range(nSymb):
            for ii in range(0,int(seqDuration/periods[si])+1):
                ei = int(round(ii*periods[si]/isi)) # convert to event number
                if  ei < nEvent: stimSeq[ei][si]=1
        return StimSeq(stimTime_ms,stimSeq)

    def phaseShiftKey(self,speedup=False):
        ''' Convert a normal encoded stim sequence into a phase-shift-keyed version where
            0 -> 01, and 1 -> 10.
            speedup - if true then keep duration the same but half the isi, false = double duration.'''
        if speedup:
            st=[]
            for i in range(len(self.stimTime_ms)-1): # insert new point between existing ones
                st += [self.stimTime_ms[i], self.stimTime_ms[i]+(self.stimTime_ms[i+1]-self.stimTime_ms[i])//2]
            st += [self.stimTime_ms[-1], 
                   self.stimTime_ms[-1]+(self.stimTime_ms[-1]-self.stimTime_ms[-2])//2]
        else:
            # start again 1 isi after the end
            offset = self.stimTime_ms[-1]+self.stimTime_ms[1]-self.stimTime_ms[0] 
            st=self.stimTime_ms + [i+offset for i in self.stimTime_ms]
        self.stimTime_ms=st

        ss = [[None]*len(self.stimSeq[0]) for i in range(len(self.stimSeq)*2)]
        for ei in range(len(self.stimSeq)):
            ss[ei*2]   = self.stimSeq[ei]
            ss[ei*2+1] = [0 if ssei==1 else 1 for ssei in self.stimSeq[ei]]
        self.stimSeq=ss
        return self


# testcase code
if __name__ == "__main__":
    print("Noise:" + str(stimseq.StimSeq.mkStimSeqNoise(4,3,.1)))
    print("Scan: " + str(stimseq.StimSeq.mkStimSeqScan(4,3,.1)))
    print("Rand: " + str(stimseq.StimSeq.mkStimSeqRand(4,3,.1)))
    print("Odd:  " + str(stimseq.StimSeq.mkStimSeqOddball(1,3,.4)))
    print("SSEP: " + str(stimseq.StimSeq.mkStimSeqSSEP(4,3,.1,[x*.1 for x in [2,3,4,5]])))
    print("gold: " + str(stimseq.StimSeq.fromString("../../stimulus/gold_10hz.txt")))
    print("interval:" + str(stimseq.StimSeq.mkStimSeqInterval(2,4,.15,[3*.15,4*.15])))
    print("Scan(psk): " + str(stimseq.StimSeq.mkStimSeqScan(4,3,.1).phaseShiftKey()))
    
