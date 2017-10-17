from smop.core import *
# addPosInfo.m

    
@function
def addPosInfo(di=None,capFile=None,overridechnms=None,prefixMatch=None,verb=None,capDir=None,*args,**kwargs):
    varargin = addPosInfo.varargin
    nargin = addPosInfo.nargin

    # add electrode position info to a dimInfo structure
    
    # [di]=addPosInfo(di,capFile,overridechnms,prefixMatch,verb,capDir)
    
    # Inputs:
#  di -- dim-info for the channels *only*
#        OR
#        {chnms} cell array of channel names to get pos-info for
#  capFile -- file name of a file which contains the pos-info for this cap
#  overridechnms -- flag that we should ignore the channel names in di
#  prefixMatch  -- [bool] match channel names if only the start matches?
#  verb         -- [int] verbosity level  (0)
#  capDir       -- 'str' directory to search for capFile
    if nargin < 2 or isempty(capFile):
        capFile='b'1010''
# addPosInfo.m:15
    
    if nargin < 3:
        overridechnms=0
# addPosInfo.m:16
    
    
    if nargin < 4 or isempty(prefixMatch):
        prefixMatch=0
# addPosInfo.m:17
    
    if nargin < 5 or isempty(verb):
        verb=0
# addPosInfo.m:18
    
    if nargin < 6:
        capDir=matlabarray([])
# addPosInfo.m:19
    
    Cnames,latlong,xy,xyz=readCapInf(capFile,capDir,nargout=4)
# addPosInfo.m:20
    if isstruct(di):
        vals=di.vals
# addPosInfo.m:21
    else:
        vals=copy(di)
# addPosInfo.m:23
        if iscell(vals):
            tmp=cellarray([vals])
# addPosInfo.m:24
        else:
            tmp=copy(vals)
# addPosInfo.m:24
        di=struct('b'name'','b'ch'','b'units'',[],'b'vals'',tmp,'b'extra'',[])
# addPosInfo.m:25
    
    if ((isnumeric(vals) or (logical_not(isempty(overridechnms)) and overridechnms))):
        #     && numel(Cnames)<=numel(vals)  )
        ovals=copy(vals)
# addPosInfo.m:29
        if isnumeric(vals):
            vals=num2cell(ravel(vals))
# addPosInfo.m:30
        if isempty(vals):
            vals[1:numel(Cnames)]=Cnames
# addPosInfo.m:31
        else:
            vals[1:min(end(),numel(Cnames))]=Cnames[1:min(numel(vals),end())]
# addPosInfo.m:32
    
    # Add the channel position info, and iseeg status
    chnm=cellarray([])
# addPosInfo.m:36
    matchedCh=false(numel(Cnames),1)
# addPosInfo.m:36
    for i in arange(1,numel(vals)).reshape(-1):
        ti=0
# addPosInfo.m:38
        if iscell(vals):
            chnm[i]=vals[i]
# addPosInfo.m:39
        else:
            chnm[i]=vals[i]
# addPosInfo.m:39
        if (ischar(chnm[i])):
            for j in arange(1,numel(Cnames)).reshape(-1):
                if (logical_not(matchedCh[j]) and strcmp(lower(chnm[i]),lower(Cnames[j]))):
                    ti=copy(j)
# addPosInfo.m:44
                    matchedCh[j]=true
# addPosInfo.m:44
                    break
            if (prefixMatch and ti == 0):
                for j in arange(1,numel(Cnames)).reshape(-1):
                    if (logical_not(matchedCh[j]) and logical_not(isempty(strmatch(lower(Cnames[j]),lower(chnm[i]))))):
                        ti=copy(j)
# addPosInfo.m:51
                        matchedCh[j]=true
# addPosInfo.m:51
                        break
        else:
            if (isnumeric(chnm[i]) and i <= numel(Cnames)):
                chnm[i]=Cnames[i]
# addPosInfo.m:56
                ti=copy(i)
# addPosInfo.m:57
                matchedCh[i]=true
# addPosInfo.m:58
            else:
                ti=0
# addPosInfo.m:60
                warning('b'Channel names are difficult'')
        tii[i]=ti
# addPosInfo.m:63
        if (logical_not(isempty(ti)) and numel(ti) == 1 and ti > 0 and ti <= size(xy,2)):
            if verb > 0:
                fprintf('b'%3d) Matched : %s\\\\t ->\\\\t %s\\\\n'',i,chnm[i],Cnames[ti])
            chnm[i]=Cnames[ti]
# addPosInfo.m:66
            di.extra(i).pos2d = copy(xy[:,ti])
# addPosInfo.m:67
            di.extra(i).pos3d = copy(xyz[:,ti])
# addPosInfo.m:68
            di.extra(i).iseeg = copy(true)
# addPosInfo.m:69
            if (any(isnan(di.extra(i).pos2d)) or any(isnan(di.extra(i).pos3d)) or any(isinf(di.extra(i).pos2d)) or any(isinf(di.extra(i).pos3d))):
                di.extra(i).iseeg = copy(false)
# addPosInfo.m:72
        else:
            di.extra(i).pos2d = copy(cat([- 1],[1]))
# addPosInfo.m:75
            di.extra(i).pos3d = copy(cat([- 1],[1],[0]))
# addPosInfo.m:76
            di.extra(i).iseeg = copy(false)
# addPosInfo.m:77
    
    di.vals = copy(chnm)
# addPosInfo.m:80
    return di
    #---------------------------------------------------------------
    
@function
def testCase(*args,**kwargs):
    varargin = testCase.varargin
    nargin = testCase.nargin

    # with di as input
    addPosInfo(di)
    # with cell array of channel names as input
    Cnames=cellarray(['b'Cz'','b'CPz''])
# addPosInfo.m:87
    addPosInfo(Cnames)