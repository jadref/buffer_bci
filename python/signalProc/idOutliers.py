# Generated with SMOP  0.41-beta
from libsmop import *
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m

    
@function
def idOutliers(X=None,dim=None,thresh=None,feat=None,maxIter=None,verb=None,*args,**kwargs):
    varargin = idOutliers.varargin
    nargin = idOutliers.nargin

    # identify outlining elements in a matrix using robust variance/mean computation
    
    # [badInd,feat,threshs,stdfeat,mufeat]=idOutliers(X,dim,thresh,feat,maxIter,verb)
    
    # Inputs:
#  X      -- [n-d] data to identify outling elements of
#  dim    -- dimension(s) along which to look for outlying elements
#  thresh -- [2x1] threshold in data-std-deviations std-deviations to test to remove
#            1st element is threshold above (3), 2nd is threshold below (-inf)
#  idx    -- [Nx1] or [size(X,dim) bool] sub-set of indicies along dim to consider
#  maxIter-- [int] number of times round the remove+re-compute var loop (6)
#  feat   -- [str] which feature type to use {'mu','var'}  ('var')
#  summary-- additional descriptive info
    
    if nargin < 2 or isempty(dim):
        dim=1
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:16
    
    if nargin < 3 or isempty(thresh):
        thresh=3.5
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:17
    
    if nargin < 4 or isempty(feat):
        feat='var'
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:18
    
    if nargin < 5 or isempty(maxIter):
        maxIter=3
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:19
    
    if nargin < 6 or isempty(verb):
        verb=0
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:20
    
    szX=size(X)
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:22
    # compute stds over this dim
    rdims=setdiff(arange(1,ndims(X)),dim)
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:25
    stds,mus=mvar(X,rdims,nargout=2)
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:26
    stds=sqrt(abs(stds))
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:27
    if prod(szX(rdims)) == 1:
        stds=copy(mus)
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:28
    
    
    if strcmp(feat,'var'):
        feat=copy(stds)
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:30
    else:
        if strcmp(feat,'mu'):
            feat=copy(mus)
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:31
        else:
            if (isnumeric(feat) and isequal(size(feat),szX(dim))):
                feat=copy(feat)
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:33
            else:
                error('Unrecognised feature type: %s',feat)
    
    badInd=false(size(feat))
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:37
    threshs=[]
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:38
    for iter in arange(1,maxIter).reshape(-1):
        mufeat[iter]=median(feat(logical_not(badInd)))
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:41
        stdfeat[iter]=std(feat(logical_not(badInd)))
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:42
        # remove anything too far from the mean std,std
        threshs[1,iter]=mufeat(iter) + dot(thresh(1),stdfeat(iter))
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:45
        badIndi=(feat > threshs(1,iter))
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:46
        if (numel(thresh) > 1):
            threshs[2,iter]=mufeat(iter) - dot(thresh(2),stdfeat(iter))
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:48
            badIndi=logical_or(badIndi,(feat < threshs(2,iter)))
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:49
        if sum(logical_or(badIndi,badInd)) == sum(badInd):
            break
        #if(verb>0)fprintf('#d) #d removed =  #d',iter,sum(badIndi-badInd),sum(badInd)); end;
        badInd=logical_or(badInd,badIndi)
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:53
    
    return badInd,feat,threshs,stdfeat,mufeat
    #------------------------------------------------------------
    
@function
def testCase(*args,**kwargs):
    varargin = testCase.varargin
    nargin = testCase.nargin

    X=randn(1000,1)
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:58
    oI=randn(size(X)) > 1
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:59
    X[oI]=dot(X(oI),5)
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:59
    bad=idOutliers(X)
# /Users/jdrf/source/buffer_bci/matlab/signalProc/idOutliers.m:60