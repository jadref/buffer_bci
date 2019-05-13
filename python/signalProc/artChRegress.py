import numpy as np

def artChRegress(X,idx,dim=None,center=False,verbose=True):
# remove any signal correlated with the input signals from the data
# 
#   [X,w]=artChRegress(X,dim,idx,...);# incremental calling mode    
# N.B. important for this regression to ensure only the **pure** artifact signal goes into removal.  
#      Thus use the pre-processing options ('detrend','center','bands') to do some additional 
#      pre-processing before the removal    
# Inputs:
#  X   -- [n-d] the data to be deflated/art channel removed
#  dim -- [1 x 2] = the dimension along which to correlate/deflate, i.e. channel dimesion      (-1)
#                   the dimension along which to pre-process the artifact channels, i.e. time  (-2)
#  idx -- [1 x nArt] the index/indicies along dim to use as artifact channels ([])
#  center  -- [boolean] center in time (0-mean) the artifact signal before removal (True)
#       N.B. if using detrend/center please call with large enough time blocks
#            that an artifact is a small part of the time...
    if dim is None : dim    = [X.ndim-1,X.ndim-2] # last 2 dims
    if isinstance(dim,int) : dim = [dim,dim-1] # ensure at least 2 values
        
    chD   = dim[0]
    timeD = dim[1]
    if len(dim)<3 : # all at once
        epD = None
        nEp = 1
    else : # multiple epochs
        epD = dim[2:] # [ i for i in range(X.ndim) if not i in dim ]
        if len(epD)>1 :raise("Multiple epoch dimensions not supported yet!")
        epD = epD[0]
        nEp = X.shape[epD]

    # make some index expressions for slicing the bits we need
    # epoch extractor
    xidx = [slice(None)] * len(X.shape)
    # N.B. use slices if want to avoid removing this dimension...
    if not epD is None: xidx[epD] = [0] # epoch subset
    # artifact channel extractor
    artIdx = [slice(None)] * len(X.shape) # slice the whole array
    artIdx[chD]=idx # art-ch subset
    # indices to accumulate for covariance computation, everything but chD and epD
    tpIdx=tuple([i for i in range(X.ndim) if not i==chD])
    
    if verbose: print('artChRegress %d:'%nEp,end='')
    Y = np.zeros(X.shape)
    for epi in range(nEp):
        if verbose : print('.',end='')
        # extract the current data bit to work on
        if not epD is None: xidx[epD]=[epi]
        Xei=X[tuple(xidx)] # [ ch x time ]
        if verbose>1: print('Xei = '+str(Xei.shape))
        # extract the artifact signals for this epoch
        artSig=Xei[tuple(artIdx)]
        if center : 
            artSig= artSig - np.mean(artSig,axis=timeD,keepdims=True)
            # pushback pre-processing changes
            Xei[tuple(artIdx)]=artSig

        # compute the artifact covariance
        BXXtB=np.tensordot(artSig,artSig,(tpIdx,tpIdx)) #tpIdx,[],tpIdx2) # [ nArtCh x nArtCh ]
        # get the artifact/channel cross-covariance
        BXYt =np.tensordot(artSig,Xei,(tpIdx,tpIdx))
        # regression solution for estimateing X from the artifact channels: w_B = (B^TXX^TB)^{-1} B^TXY^T = (BX)\Y
        #w_B    = BXXtB\BXYt; # slower, min-norm, low-rank robust(ish) [nArt x nCh]
        # N.B. numpy specifes the tolerance as rcond not abs magnitude!
        iBXXtB = np.linalg.pinv(BXXtB,.005)
        w_B= iBXXtB @ BXYt # [ nArtCh x nCh ]
        # w_B=np.dot(np.linalg.pinv(BXXtB,tol),BXYt)
        w_B[:,idx]=0 # ensure art-channels aren't changed
        # make a single spatial filter to remove the artifact signal in 1 step
        #  X-w*X = X*(I-w)
        sf=np.eye(X.shape[chD]) # [ nCh x nCh ]
        sf[idx,:]=sf[idx,:] - w_B  
        # apply the deflating spatial filter and update in place
        Yei = np.tensordot(Xei,sf,((chD),(0)))
        Y[tuple(xidx)]=Yei
    if verbose : print('')    
    return (Y,sf)
    
if __name__=="__main__":
    # build a toy testcase
    S  = np.random.randn(10,100,10) # tr x ep x ch
    N  = np.random.randn(S.shape[0],S.shape[1],2) # tr x ep x nNoise
    sf = np.random.randn(N.shape[2],S.shape[2]) # nNoise x ch - spatial patterns
    Xn = np.matmul(N,sf) # [ tr x ep x nCh ]
    X  = np.concatenate((N,S + Xn),2) # measured is [tr x ep x [nNoise,signal + noise]]

    print("All-at-once deflation")
    Y,w= artChRegress(X,idx=range(N.shape[-1]),center=True)
    SAE = np.sum(np.abs(S-X[:,:,N.shape[-1]:]))
    SAEY= np.sum(np.abs(S-Y[:,:,N.shape[-1]:]))
    print("Relative art strength: %g (%g/%g)  ((Y-S)/(X-S))"%(SAEY/SAE,SAEY,SAE))

    print("Per epoch deflation")
    Y,w= artChRegress(X,dim=[2,1,0],idx=range(N.shape[-1]),center=True)
    SAE = np.sum(np.abs(S-X[:,:,N.shape[-1]:]))
    SAEY= np.sum(np.abs(S-Y[:,:,N.shape[-1]:]))
    print("Relative art strength: %g (%g/%g)  ((Y-S)/(X-S))"%(SAEY/SAE,SAEY,SAE))
    
#     tmp=cat(4,S,S - X,Y - S)
#     clf
#     mimage(squeeze(mean(abs(tmp(arange(size(sf,2) + 1,end()),arange(),arange(),arange())),3)),'clim',concat([0,mean(abs(ravel(tmp)))]),'colorbar',1,'title',cellarray(['S','S-X','S-Y']))
#     colormap('ikelvin')
#     clf
#     mimage(squeeze(tmp(arange(),arange(),1,arange())),'title',cellarray(['S','S-X','S-Y']),'colorbar',1)
#     Y2=artChRm(X,1,concat([1,2]))
# # artChRegress.m:293
#     clf
#     mimage(S,Y2 - S,'clim','cent0','colorbar',1)
#     colormap('ikelvin')
#     # regress per-epoch
#     Y,info=artChRegress(X,[],concat([1,2,3]),concat([1,2]),nargout=2)
# # artChRegress.m:297
    
#     Yi(arange(),arange(),1),state=artChRegress(X(arange(),arange(),1),[],concat([1,2,3]),concat([1,2]),nargout=2)
# # artChRegress.m:300
#     for epi in arange(2,size(X,3)).reshape(-1):
#         textprogressbar(epi,size(X,3))
#         Yi(arange(),arange(),epi),state=artChRegress(X(arange(),arange(),epi),state,nargout=2)
# # artChRegress.m:303
    
#     mad(Y,Yi)
#     # with additional artifact channel pre-filtering
#     Y=artChRegress(X,[],1,concat([1,2]),'fs',100,'center',0,'bands',concat([0,10,inf,inf]),'artfilttype','fft')
# # artChRegress.m:308
    
#     Y=artChRegress(X,[],1,concat([1,2]),'fs',100,'center',0,'bands',concat([0,10,inf,inf]),'artfilttype','iir')
# # artChRegress.m:309
    
#     # specify channels with names mode
#     Y,info=artChRegress(X,[],[],cellarray(['C1','C2']),'ch_names',cellarray(['C1','C2','C3','C4','C5','C6','C7','C8','C9','C10']),nargout=2)
# # artChRegress.m:313
