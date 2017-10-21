import numpy as np
from readCapInf import *

def getPosInfo(chnames=None,capFile='1010',overridechnms=0,prefixMatch=False,verb=0,capDir=None):
    """
     add electrode position info to a dimInfo structure
    
     cnames,pos2d,pos3d,iseeg=getPosInfo(di,capFile,overridechnms,prefixMatch,verb,capDir)
    
     Inputs:
    cnames -- channel names to get pos-info for
    capFile -- file name of a file which contains the pos-info for this cap
    overridechnms -- flag that we should ignore the channel names in di
    prefixMatch  -- [bool] match channel names if only the start matches?
    verb         -- [int] verbosity level  (0)
    capDir       -- 'str' directory to search for capFile
    """
    cfnames,latlong,xy,xyz,cfile=readCapInf(capFile,capDir)
    
    if overridechnms  or (isinstance(cfnames,np.ndarray) and np.issubdtype(cfnames.dtype,np.number)) :
        if chnames is None:
            chnames = cfnames
        else:
            if len(chnames)<len(cfnames):
                chnames = cfnames[1:len(chnames)]
            else:
                chnames[1:len(cfnames)]=cfnames
                
    # Add the channel position info, and iseeg status
    # pre-allocate for the output
    pos2d=np.zeros((2,len(chnames)),dtype=np.float)
    pos3d=np.zeros((3,len(chnames)),dtype=np.float)
    iseeg=np.zeros((len(chnames)),  dtype=np.bool)
    cfmatched=np.zeros((len(cfnames),1),dtype=np.bool) # file channels matched
    for i,chnamei in enumerate(chnames):
        ti=0
        if isinstance(chnamei,str):
            for j,cfnamej in enumerate(cfnames):
                if verb>1 : print("Trying %s == %s?"%(chnamei,cfnamej),end='')
                if not cfmatched[j] and chnamei.lower()==cfnamej.lower():
                    if verb>1 : print("matched")
                    ti=j
                    cfmatched[j]=True
                    break
            if prefixMatch and ti == 0:
                for j in range(0,numel(cfnames)):
                    if not cfmatched[j] and lower(cfnamej).startswith(lower(chnamei)):
                        ti=j
                        cfmatched[j]=True
                        break
        else:
            if (isnumeric(chnamei) and i <=len(cfnames)):
                ti=chnamei
                cfmatched[chnamei]=True
            else:
                ti=0
                warning('Channel names are difficult')

        # got the match, so update the info
        if (not ti is None and ti > 0 and ti <= len(cfnames)):
            if verb >= 0:
                print('%3d) Matched : %s\t ->\t %s'%(i,chnames[i],cfnames[ti]))
            chnames[i] =cfnames[ti]
            pos2d[:,i]=xy[:,ti]
            pos3d[:,i]=xyz[:,ti]
            iseeg[i]  =True
            if any(np.isnan(pos2d[i])) or any(np.isnan(pos3d[i])) or any(np.isinf(pos2d[i])) or any(np.isinf(pos3d[i])):
                di.extra[i].iseeg = False
# addPosInfo.m:72
        else:
            pos2d[:,i] = (-1,1)
            pos3d[:,i] = (-1,1,0)
            iseeg[i] = False
    
# addPosInfo.m:80
    return (chnames,pos2d,pos3d,iseeg)

def testCase():
    import importlib
    import getPosInfo
    importlib.reload(getPosInfo)
    cn,xy,xyz,iseeg=getPosInfo.getPosInfo(['CPz','AFz'],'1010')
