import numpy as np
from readCapInf import *

def addPosInfo(chnames=None,capFile='1010',overridechnms=0,prefixMatch=False,verb=0,capDir=None):
    """
     add electrode position info to a dimInfo structure
    
     [di]=addPosInfo(di,capFile,overridechnms,prefixMatch,verb,capDir)
    
     Inputs:
    cnames -- channel names to get pos-info for
    capFile -- file name of a file which contains the pos-info for this cap
    overridechnms -- flag that we should ignore the channel names in di
    prefixMatch  -- [bool] match channel names if only the start matches?
    verb         -- [int] verbosity level  (0)
    capDir       -- 'str' directory to search for capFile
    """
    cfnames,latlong,xy,xyz=readCapInf(capFile,capDir)
    
    if isnumeric(chnames) or overridechnms :
        if chnames is None:
            chnames = cfnames
        else:
            if len(chnames)<len(cfnames):
                chnames = cfnames[1:len(chnames)]
            else:
                chnames[1:len(cfnames)]=cfnames
    
    # Add the channel position info, and iseeg status
    chnm=[]
    matchedCh=np.zeros((len(Cnames),1),dtype=np.bool)
    for i in range(0,len(chnames)):
        ti=0
        chiname=chnames[i]
        if (ischar(chiname)):
            for j in range(0,numel(cfnames)):
                if not matchedCh[j] and chiname.lower()==cfnames[j].lower():
                    ti=j
                    matchedCh[j]=True
                    break
            if prefixMatch and ti == 0:
                for j in range(0,numel(cfnames)):
                    if not matchedCh[j] and strmatch(lower(Cnames[j]),lower(chnm[i])):
                        ti=j
                        matchedCh[j]=True
                        break
        else:
            if (isnumeric(chiname) and i <=len(Cnames)):
                chanme[i]=cfname[i]
                ti=i
                matchedCh[i]=True
            else:
                ti=0
                warning('Channel names are difficult')
        tii[i]=ti
        if (not ti is None and ti > 0 and ti <= xs.shape[1]):
            if verb > 0:
                fprintf('b'%3d) Matched : %s\\\\t ->\\\\t %s\\\\n'',i,chnm[i],Cnames[ti])
            chname[i]=cfnames[ti]
            pos2d[i] = xy[:,ti]
            pos3d[i] = xyz[:,ti]
            iseeg[i] = True
            if any(np.isnan(pos2d[i])) or any(np.isnan(pos3d[i])) or any(np.isinf(pos2d[i])) or any(np.isinf(pos3d[i])):
                di.extra[i].iseeg = False
# addPosInfo.m:72
        else:
            pos2d[i] = (-1,1)
            pos3d[i] = (-1,1,0)
            iseeg[i] = False
    
# addPosInfo.m:80
    return (chnames,pos2d,pos3d,iseeg)
