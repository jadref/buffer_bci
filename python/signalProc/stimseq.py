# TODO :
#  [] - load sequence from file
#  [] - use of the event sequence
#  [] - noise codes stimulus
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
            res += "(" + str(len(self.stimSeq)) + "," + str(len(self.stimSeq[0])) + ")\n"
            for i in range(len(self.stimSeq)):
                for j in range(0,len(self.stimSeq[i])-1):
                    res += str(self.stimSeq[i][j]) + " "
                res+= str(self.stimSeq[i][-1]) + "\n"
        else:
            res+= "<null>\n"
        res+="\n\n"
        return res

    @staticmethod
    def fromString(str):
        raise("Error not defined yet")
        
        return StimSeq()

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
        



# testcase code
if __name__ == "__main__":
    print("Noise:" + stimseq.StimSeq.mkStimSeqNoise(4,3,.1))
    print("Scan: " + stimseq.StimSeq.mkStimSeqScan(4,3))
    print("Rand: " + stimseq.StimSeq.mkStimSeqRand(4,3))
    print("Odd:  " + stimseq.StimSeq.mkStimSeqOddball(1,3,.4))
    print("SSEP: " + stimseq.StimSeq.mkStimSeqSSEP(4,3,.1,[2,3,4,5]))
    
