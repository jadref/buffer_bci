# Generated with SMOP  0.41-beta
from libsmop import *
# artChRegress.m

    
@function
def artChRegress(X=None,state=None,dim=None,idx=None,varargin=None,*args,**kwargs):
    varargin = artChRegress.varargin
    nargin = artChRegress.nargin

    # remove any signal correlated with the input signals from the data
# 
#   [X,state,info]=artChRegress(X,state,dim,idx,...);# incremental calling mode
    
    # N.B. important for this regression to ensure only the **pure** artifact signal goes into removal.  
#      Thus use the pre-processing options ('detrend','center','bands') to do some additional 
#      pre-processing before the removal
    
    # Inputs:
#  X   -- [n-d] the data to be deflated/art channel removed
#  state -- [struct] internal state of the filter. Init-filter if empty.   ([])
#  dim -- dim(1) = the dimension along which to correlate/deflate ([1 2 3])
#         dim(2) = the time dimension for spectral filtering/detrending along
#         dim(3) = compute regression separately for each element on this dimension
#  idx -- [1 x nArt] the index/indicies along dim(1) to use as artifact channels ([])
#        OR
#         {'str' 1 x nArt} names of the artifact channels.  These will be matched with the 'ch_names' option.
#           with any missing names ignored.  Note: in the absence of an exact match *any* channel with the same prefix will be matched
# Options:
#  artFiltType -- type of additional temporal filter to apply to the artifact signals before ('fft')
#                 regressing them out. one-of 'fft'=fftfilter, 'iir'=butterworth filter
#  bands   -- spectral filter (as for fftfilter) to apply to the artifact signal ([])
#             N.B. this should be such that the filtered artifact channel as as close to the pure
#                  propogated artifact as you can get..
#  fs  -- the sampling rate of this data for the time dimension ([])
#         N.B. fs is only needed if you are using a spectral filter, i.e. bands.
#  detrend -- detrend the artifact before removal                        (0)
#  center  -- [int] center in time (0-mean) the artifact signal before removal (2)
#               center=1 : normal center, center=2 : median-center
#       N.B. if using detrend/center please call with large enough time blocks
#            that an artifact is a small part of the time...
#  covFilt -- {str} function to apply to the computed covariances to smooth them prior to regression {''}
#              SEE: biasFilt for example function format
#            OR
#             [float] half-life to use for simple exp-moving average filter
#                   N.B. this time-constant needs to be *long* enough to get a robust cross-channel
#                   covariance estimate, but *short* enough to respond to transient artifacts which 
#                   appear and disappear.  For eye-artifacts a number of about .5-1s works well.
#                   Note: alpha = exp(log(.5)./(half-life)), half-life = log(.5)/log(alpha)
#  ch_names -- {'str' size(X,dim(1))} cell array of strings of the names of the channels in dim(1) of X
#  ch_pos   -- [3 x size(X,dim(1))] physical positions of the channels in dim(1) of X
    
    # TODO:
#    [X] Correct state propogate over calls for the EOG data pre-processing, i.e. convert to IIR/Butter for band-pass
#    [] Spatio-temporal learning - learn the optimal spectral filter as well as spatial
#    [] Switching-mode removal   - for transient artifacts add artifact detector to only learn covariance function when artifact is present..
    opts=struct('detrend',0,'center',2,'bands',[],'step_samp',[],'artfilttype','iir','fs',[],'verb',0,'covFilt',[],'filtstate',[],'ch_names',[],'ch_pos',[],'pushbackartsig',1)
# artChRegress.m:48
    if (logical_not(isempty(state)) and isstruct(state)):
        # extract the arguments/state
        opts=copy(state)
# artChRegress.m:51
        dim=state.dim
# artChRegress.m:52
        idx=state.idx
# artChRegress.m:53
        artFilt=state.artFilt
# artChRegress.m:54
    else:
        opts=parseOpts(opts,varargin)
# artChRegress.m:56
        artFilt=[]
# artChRegress.m:57
        if (iscell(idx) and logical_not(isempty(opts.ch_names))):
            # find the matching entries
            tmp=copy(idx)
# artChRegress.m:61
            idx=[]
# artChRegress.m:61
            for ii in arange(1,numel(tmp)).reshape(-1):
                mi=strcmp(tmp[ii],opts.ch_names)
# artChRegress.m:63
                if logical_not(any(mi)):
                    mi=strcmpi(tmp[ii],opts.ch_names)
# artChRegress.m:64
                if logical_not(any(mi)):
                    mi=strncmpi(tmp[ii],opts.ch_names,numel(tmp[ii]))
# artChRegress.m:65
                if any(mi):
                    mi=find(mi)
# artChRegress.m:66
                    idx=concat([[idx],[mi]])
# artChRegress.m:66
                if (opts.verb > 0):
                    if any(mi):
                        fprintf('artChRegress:: %s -> %s\n',tmp[ii],sprintf('%s,',opts.ch_names[mi]))
                    else:
                        fprintf('artChRegress:: %s unmatched\n',tmp[ii])
            if (isempty(idx)):
                fprintf('artChRegress:: Warning, no artifact channels given!')
    
    if (isempty(idx)):
        state=copy(opts)
# artChRegress.m:79
        state.dim = copy(dim)
# artChRegress.m:79
        state.idx = copy(idx)
# artChRegress.m:79
        state.artFilt = copy([])
# artChRegress.m:80
        state.covFilt = copy([])
# artChRegress.m:80
        state.filtstate = copy([])
# artChRegress.m:80
        info=[]
# artChRegress.m:81
        return X,state,info
    
    dim[dim < 0]=ndims(X) + 1 + dim(dim < 0)
# artChRegress.m:85
    if isempty(dim):
        dim=concat([1,2,3])
# artChRegress.m:86
    
    if numel(dim) < 2:
        dim[2]=dim(1) + 1
# artChRegress.m:87
    
    szX=size(X)
# artChRegress.m:88
    szX[arange(end() + 1,max(dim))]=1
# artChRegress.m:88
    if numel(dim) < 3:
        nEp=1
# artChRegress.m:89
    else:
        nEp=szX(dim(3))
# artChRegress.m:89
    
    issingle=isa(X,'single')
# artChRegress.m:90
    
    # set-up the covariance filtering function
    covFilt=opts.covFilt
# artChRegress.m:94
    filtstate=opts.filtstate
# artChRegress.m:94
    if (logical_not(isempty(covFilt))):
        if logical_not(iscell(covFilt)):
            covFilt=cellarray([covFilt])
# artChRegress.m:96
        if (isnumeric(covFilt[1])):
            if (covFilt[1] > 1):
                covFilt[1]=exp(log(0.5) / covFilt[1])
# artChRegress.m:99
            if isempty(opts.step_samp):
                opts.step_samp = copy(dot(ceil(log(0.5) / log(covFilt[1])),2))
# artChRegress.m:101
            if isempty(filtstate):
                filtstate=struct('N',0,'sxx',0,'sxy',0)
# artChRegress.m:102
        else:
            filtstate=struct('XX',[],'XY',[])
# artChRegress.m:104
    
    # re-shape X into smaller steps if wanted/possible...
    step_samp=opts.step_samp
# artChRegress.m:108
    if (logical_not(isempty(step_samp))):
        if (szX(dim(2)) > dot(opts.step_samp,1.5)):
            step_samp=ceil(szX(dim(2)) / ceil(szX(dim(2)) / step_samp))
# artChRegress.m:111
        else:
            step_samp=[]
# artChRegress.m:113
    
    # compute the artifact signal and its forward propogation to the other channels
# N.B. convert to use IIR to allow high-pass between calls with small windows...
    if (isempty(artFilt) and logical_not(isempty(opts.bands))):
        fs=opts.fs
# artChRegress.m:121
        if isempty(fs):
            warning('Sampling rate not specified.... using default=100Hz')
            fs=100
# artChRegress.m:122
        if (strcmpi(opts.artfilttype,'fft')):
            if opts.verb > 0:
                fprintf('artChRegress::Filtering @%gHz with [%s]\n',fs,sprintf('%g ',opts.bands))
            artFilt=mkFilter(floor(szX(dim(2)) / 2),opts.bands,fs / szX(dim(2)))
# artChRegress.m:125
        else:
            type_=opts.artfilttype
# artChRegress.m:127
            bands=opts.bands
# artChRegress.m:128
            fprintf('artChRegress::')
            if numel(bands) > 2:
                bands=bands(arange(2,3))
# artChRegress.m:130
            if bands(1) < 0:
                type_='low'
# artChRegress.m:131
                bands=bands(2)
# artChRegress.m:131
                fprintf('low-pass %gHz\n',bands)
            else:
                if bands(2) > fs:
                    type_='high'
# artChRegress.m:132
                    bands=bands(1)
# artChRegress.m:132
                    fprintf('high-pass %gHz\n',bands)
                else:
                    fprintf('band-pass [%g-%g]Hz\n',bands)
            # N.B. we use a low-order butterworth to minimise the phase-lags introduced...
            if any(strcmpi(type_,cellarray(['bandpass','iir']))):
                type_=[]
# artChRegress.m:136
            if isempty(type_):
                B,A=butter(3,dot(bands,2) / fs,nargout=2)
# artChRegress.m:137
            else:
                B,A=butter(3,dot(bands,2) / fs,type_,nargout=2)
# artChRegress.m:138
            artFilt=struct('B',B,'A',A,'filtstate',[],'type',opts.artfilttype)
# artChRegress.m:140
    
    # make a index expression to extract the current epoch
    xidx=cellarray([])
# artChRegress.m:145
    for di in arange(1,numel(szX)).reshape(-1):
        xidx[di]=int32(arange(1,szX(di)))
# artChRegress.m:145
    
    # index expression to extract the artifact channels
    artIdx=cellarray([])
# artChRegress.m:147
    for di in arange(1,numel(szX)).reshape(-1):
        artIdx[di]=int32(arange(1,szX(di)))
# artChRegress.m:147
    
    artIdx[dim(1)]=idx
# artChRegress.m:147
    if numel(dim) > 2:
        artIdx[dim(3)]=1
# artChRegress.m:147
    
    # tprod-arguments for computing the channel-covariance matrix
    tpIdx=- (arange(1,ndims(X)))
# artChRegress.m:149
    tpIdx[dim(1)]=1
# artChRegress.m:149
    tpIdx2=- (arange(1,ndims(X)))
# artChRegress.m:150
    tpIdx2[dim(1)]=2
# artChRegress.m:150
    sf=[]
# artChRegress.m:152
    if opts.verb > 0 and nEp > 10:
        fprintf('artChRegress:')
    
    epi=1
# artChRegress.m:154
    sampi=1
# artChRegress.m:154
    while epi < nEp + 1:

        # get the piece of data to work on this time
        if (numel(dim) < 2 and isempty(step_samp)):
            Xei=copy(X)
# artChRegress.m:159
        else:
            xidx[dim(3)]=epi
# artChRegress.m:161
            if (logical_not(isempty(step_samp))):
                sampidx=arange(sampi,min(szX(dim(2)),sampi + step_samp - 1))
# artChRegress.m:163
                xidx[dim(2)]=sampidx
# artChRegress.m:164
                artIdx[dim(2)]=arange(1,numel(sampidx))
# artChRegress.m:165
            # update for next round
            if (logical_not(isempty(step_samp))):
                if (sampidx(end()) < szX(dim(2))):
                    sampi=sampi + step_samp
# artChRegress.m:170
                else:
                    sampi=1
# artChRegress.m:172
                    epi=epi + 1
# artChRegress.m:173
                    if strncmp(artFilt.type(arange(end(),1,- 1)),fliplr('epoch'),4):
                        artFilt.filtstate = copy([])
# artChRegress.m:175
                    if opts.verb > 0 and nEp > 10:
                        textprogressbar(epi,nEp)
            else:
                epi=epi + 1
# artChRegress.m:179
                if strncmp(artFilt.type(arange(end(),1,- 1)),fliplr('epoch'),4):
                    artFilt.filtstate = copy([])
# artChRegress.m:181
                if opts.verb > 0 and nEp > 10:
                    textprogressbar(epi,nEp)
            # extract the current data bit to work on
            Xei=X(xidx[arange()])
# artChRegress.m:185
        # extract the artifact signals for this epoch
        artSig=Xei(artIdx[arange()])
# artChRegress.m:189
        if issingle:
            artSig=double(artSig)
# artChRegress.m:190
        if isequal(opts.center,1):
            artSig=repop(artSig,'-',mean(artSig,dim(2)))
# artChRegress.m:192
        else:
            if isequal(opts.center,2):
                artSig=repop(artSig,'-',median(artSig,dim(2)))
# artChRegress.m:193
        if opts.detrend:
            artSig=detrend(artSig,dim(2))
# artChRegress.m:195
        if (logical_not(isempty(artFilt))):
            if (isstruct(artFilt)):
                A=artFilt.A
# artChRegress.m:198
                B=artFilt.B
# artChRegress.m:198
                artfiltstate=artFilt.filtstate
# artChRegress.m:199
                if (isempty(artfiltstate)):
                    lrefl=dot(3,max(numel(A),numel(B)))
# artChRegress.m:201
                    kdc=sum(B) / sum(A)
# artChRegress.m:202
                    if (abs(kdc) < inf):
                        artfiltstate=fliplr(cumsum(fliplr(B - dot(kdc,A))))
# artChRegress.m:204
                    else:
                        artfiltstate=zeros(size(A))
# artChRegress.m:206
                    artfiltstate[1]=[]
# artChRegress.m:208
                    prePad=double(repop(dot(2,artSig(arange(),1,arange(),arange())),'-',artSig(arange(),arange(min(size(X,2),lrefl),2,- 1),arange(),arange())))
# artChRegress.m:209
                    artfiltstate=dot(ravel(artfiltstate),reshape(prePad(arange(),1,arange()),1,[]))
# artChRegress.m:210
                    artfiltstate=reshape(artfiltstate,concat([size(artfiltstate,1),size(prePad,1),size(prePad,3)]))
# artChRegress.m:211
                    ans,artfiltstate=filter(B,A,prePad,artfiltstate,2,nargout=2)
# artChRegress.m:213
                # apply the filter, and record output state, to propogate to the next call
                artSig,artFilt.filtstate=filter(artFilt.B,artFilt.A,artSig,artfiltstate,dim(2),nargout=2)
# artChRegress.m:216
            else:
                artSig=fftfilter(artSig,artFilt,[],dim(2),1)
# artChRegress.m:218
        # push-back pre-processing changes
        if (opts.pushbackartsig and (opts.detrend or opts.center or logical_not(isempty(artFilt)))):
            Xei[artIdx[arange()]]=artSig
# artChRegress.m:223
        # compute the artifact covariance
        BXXtB=tprod(artSig,tpIdx,[],tpIdx2)
# artChRegress.m:226
        # get the artifact/channel cross-covariance
        BXYt=tprod(artSig,tpIdx,Xei,tpIdx2)
# artChRegress.m:228
        # smooth the covariance filter estimates if wanted
        if (logical_not(isempty(covFilt))):
            if (isnumeric(covFilt[1])):
                alpha=covFilt[1]
# artChRegress.m:233
                alpha=alpha ** size(Xei,dim(2))
# artChRegress.m:234
                filtstate.N = copy(multiply(alpha,filtstate.N) + multiply((1 - alpha),1))
# artChRegress.m:236
                filtstate.sxx = copy(multiply(alpha,filtstate.sxx) + multiply((1 - alpha),BXXtB))
# artChRegress.m:237
                filtstate.sxy = copy(multiply(alpha,filtstate.sxy) + multiply((1 - alpha),BXYt))
# artChRegress.m:238
                BXXtB=filtstate.sxx / filtstate.N
# artChRegress.m:239
                BXYt=filtstate.sxy / filtstate.N
# artChRegress.m:240
            else:
                BXXtB,filtstate.XX=feval(covFilt[1],BXXtB,filtstate.XX,covFilt[arange(2,end())],nargout=2)
# artChRegress.m:242
                BXYt,filtstate.XY=feval(covFilt[1],BXYt,filtstate.XY,covFilt[arange(2,end())],nargout=2)
# artChRegress.m:243
        # regression solution for estimateing X from the artifact channels: w_B = (B^TXX^TB)^{-1} B^TXY^T = (BX)\Y
  #w_B    = BXXtB\BXYt; # slower, min-norm, low-rank robust(ish) [nArt x nCh]
        tol=dot(max(diag(BXXtB)),0.005)
# artChRegress.m:249
        w_B=dot(pinv(BXXtB,tol),BXYt)
# artChRegress.m:250
        w_B[arange(),idx]=0
# artChRegress.m:251
        # make a single spatial filter to remove the artifact signal in 1 step
  #  X-w*X = X*(I-w)
        sf=eye(size(X,dim(1)))
# artChRegress.m:255
        sf[idx,arange()]=sf(idx,arange()) - w_B
# artChRegress.m:256
        # apply the deflation
        if (nEp > 1):
            X[xidx[arange()]]=tprod(sf,concat([- dim(1),dim(1)]),Xei,concat([arange(1,dim(1) - 1),- dim(1),arange(dim(1) + 1,ndims(X))]))
# artChRegress.m:260
        else:
            if (opts.pushbackartsig and (opts.detrend or opts.center or logical_not(isempty(artFilt)))):
                X[artIdx[arange()]]=artSig
# artChRegress.m:263
            X=tprod(sf,concat([- dim(1),dim(1)]),X,concat([arange(1,dim(1) - 1),- dim(1),arange(dim(1) + 1,ndims(X))]))
# artChRegress.m:265
            if issingle:
                X=single(X)
# artChRegress.m:266

    
    if opts.verb > 0 and nEp > 10:
        fprintf('\n')
    
    # update the filter state
    state=copy(opts)
# artChRegress.m:272
    state.R = copy(sf)
# artChRegress.m:273
    state.dim = copy(dim)
# artChRegress.m:274
    state.idx = copy(idx)
# artChRegress.m:275
    state.artFilt = copy(artFilt)
# artChRegress.m:276
    state.covFilt = copy(covFilt)
# artChRegress.m:277
    state.filtstate = copy(filtstate)
# artChRegress.m:278
    info=struct('artSig',artSig)
# artChRegress.m:279
    return X,state,info
    #--------------------------------------------------------------------------
    
@function
def testCase(*args,**kwargs):
    varargin = testCase.varargin
    nargin = testCase.nargin

    S=randn(10,1000,100)
# artChRegress.m:283
    
    sf=randn(10,2)
# artChRegress.m:284
    
    #S(1:size(sf,2),:)=cumsum(S(1:size(sf,2),:),2); # artifact is 'high-frequency'
    N=cumsum(randn(size(sf,2),size(S,2),size(S,3)),2)
# artChRegress.m:286
    
    X=S + reshape(dot(sf,S(arange(1,size(sf,2)),arange())),size(S))
# artChRegress.m:287
    
    X[arange(1,size(sf,2)),arange(),arange()]=X(arange(1,size(sf,2)),arange(),arange()) + N
# artChRegress.m:288
    Y=artChRegress(X,[],1,concat([1,2]),'center',0)
# artChRegress.m:290
    
    tmp=cat(4,S,S - X,Y - S)
# artChRegress.m:291
    clf
    mimage(squeeze(mean(abs(tmp(arange(size(sf,2) + 1,end()),arange(),arange(),arange())),3)),'clim',concat([0,mean(abs(ravel(tmp)))]),'colorbar',1,'title',cellarray(['S','S-X','S-Y']))
    colormap('ikelvin')
    clf
    mimage(squeeze(tmp(arange(),arange(),1,arange())),'title',cellarray(['S','S-X','S-Y']),'colorbar',1)
    Y2=artChRm(X,1,concat([1,2]))
# artChRegress.m:293
    clf
    mimage(S,Y2 - S,'clim','cent0','colorbar',1)
    colormap('ikelvin')
    # regress per-epoch
    Y,info=artChRegress(X,[],concat([1,2,3]),concat([1,2]),nargout=2)
# artChRegress.m:297
    
    Yi(arange(),arange(),1),state=artChRegress(X(arange(),arange(),1),[],concat([1,2,3]),concat([1,2]),nargout=2)
# artChRegress.m:300
    for epi in arange(2,size(X,3)).reshape(-1):
        textprogressbar(epi,size(X,3))
        Yi(arange(),arange(),epi),state=artChRegress(X(arange(),arange(),epi),state,nargout=2)
# artChRegress.m:303
    
    mad(Y,Yi)
    # with additional artifact channel pre-filtering
    Y=artChRegress(X,[],1,concat([1,2]),'fs',100,'center',0,'bands',concat([0,10,inf,inf]),'artfilttype','fft')
# artChRegress.m:308
    
    Y=artChRegress(X,[],1,concat([1,2]),'fs',100,'center',0,'bands',concat([0,10,inf,inf]),'artfilttype','iir')
# artChRegress.m:309
    
    # specify channels with names mode
    Y,info=artChRegress(X,[],[],cellarray(['C1','C2']),'ch_names',cellarray(['C1','C2','C3','C4','C5','C6','C7','C8','C9','C10']),nargout=2)
# artChRegress.m:313