from random import shuffle, randint
from math import ceil

class stimSeq :
    stimSeq     = None # [ nEvent x nSymb ] stimulus code for each time point for each stimulus
    stimTime_ms = None # time stim i ends, i.e. stimulus i is on screen from stimTime_ms[i-1]-stimTime_ms[i]
    eventSeq    = None # events to send at each stimulus point

    def __init__(self,ss=None,st=None,es=None):
        self.stimSeq     = ss
        self.stimTime_ms = st
        self.eventSeq    = es

    def __str__(self):
        str = "#stimTimes: ";
        if not self.stimTime_ms is None:
            str += "(1," + len(self.stimTime_ms) + ")\n"
            for i in range(0,len(self.stimTime_ms)-1):
                str += self.stimTime_ms[i] + " "
            str+= self.stimTime_ms[-1] + "\n"
        else:
            str+= "<null>\n"
        str+= "\n\n"
        str += "#stimSeq : "
        if not self.stimSeq is None:
            str += "(" + len(self.stimSeq) + "," + len(self.stimSeq[0]) + ")\n"
            for i in range(len(self.stimSeq)):
                for j in range(0,len(self.stimSeq[i])-1):
                    str += self.stimSeq[i][j]
                str+= self.stimSeq[i][j] + "\n"
        else:
            str+= "<null>\n"
        str+="\n\n"
        return str

    def fromString(self, str):
        raise("Error not defined yet")

    def mkStimSeqScan(self, nSymb, seqDuration, isi):
        nEvent = seqDuration/isi + 1
        self.stimTime_ms = [ (ei+1)*1000.0*isi for ei in range(nEvent) ]
        self.stimSeq     = [[None]*nSymb for i in range(nEvent)]
        for ei in range(nEvent):
            self.stimSeq[ei][ei%nSymb]=1
        return self
            
    def mkStimSeqRand(self, nSymb, seqDuration, isi):
        perm = [i for i in range(nSymb)] # pre-alloc order for later shuffle
        nEvent=seqDuration/isi + 1
        self.stimTime_ms = [ (ei+1)*1000.0*isi for ei in range(nEvent) ]
        self.stimSeq     = [[None]*nSymb for i in range(nEvent)]
        for ri in range(0,nEvent,nSymb):
            shuffle(perm)
            for ei in range(nSymb):
                self.stimSeq[ri+ei][perm[ei]]=1
        return self

    def mkStimSeqOddball(self, nSymb, seqDuration, isi, tti=None, distractor=False):
        nEvent=seqDuration/isi + 1
        tti_ev      = tti/isi # ave num events between targets
        self.stimTime_ms = [ (ei+1)*1000.0*isi for ei in range(nEvent) ]
        self.stimSeq     = [[None]*nSymb for i in range(nEvent)]

        for ei in range(nSymb):
            si= 1+random.random()*tti_ev # last stimulus time
            for ri in range(0,nEvent):
                self.stimSeq[ri][ei] = 0
                if ri==int(si) :
                    self.stimSeq[ri][ei] = 1
                    si = si + tti_ev*(.5 + random.random()) # step [.5-1.5]*tti
        return self
                
    def mkStimSeqNoise(self, nSymb, seqDuration, isi, weight=.5):
        nEvent=seqDuration/isi + 1
        self.stimTime_ms = [ (ei+1)*1000.0*isi for ei in range(nEvent) ]
        self.stimSeq     = [[None]*nSymb for i in range(nEvent)]
        for ei in range(nEvent):
            for si in range(nSymb):
                if random.random() > weight :
                    self.stimSeq[ei][si]=1
        return self


# testcase code
if __name__ == "__main__":
    print("Noise:" + stimSeq().mkStimSeqNoise(4,3,.1))
    print("Scan: " + stimSeq().mkStimSeqScan(4,3))
    print("Rand: " + stimSeq().mkStimSeqRand(4,3))
    print("Odd:  " + stimSeq().mkStimSeqOddball(1,3,.4))
    
