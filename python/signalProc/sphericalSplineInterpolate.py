# Generated with SMOP  0.41-beta
from libsmop import *
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m

    
@function
def sphericalSplineInterpolate(src=None,dest=None,lambda_=None,order=None,type_=None,tol=None,verb=None,*args,**kwargs):
    varargin = sphericalSplineInterpolate.varargin
    nargin = sphericalSplineInterpolate.nargin

    #interpolate matrix for spherical interpolation based on Perrin89
    
    # W = sphericalSplineInterpolate(src,dest,lambda,order,type,tol)
    
    # Inputs:
#  src    - [3 x N] old electrode positions
#  dest   - [3 x M] new electrode positions
#  lambda - [float] regularisation parameter for smoothing the estimates (1e-5)
#  order  - [float] order of the polynomial interplotation to use (4)
#  type - [str] one of;                                         ('spline')
#             'spline' - spherical Spline 
#             'splineCAR' - as for spline but without the constant term
#                  as described in [2] this approx. the signal referenced at infinity
#             'slap'   - surface Laplician (aka. CSD)             
#  tol    - [float] tolerance for the legendre poly approx        (1e-7)
# Outputs:
#  W      - [M x N] linear mapping matrix between old and new co-ords
#  Gss    - [N x N] weight matrix from sources to sources
#  Gds    - [M x N] weight matrix from sources to destinations
#  Hds    - [M x N] lapacian deriv matrix from source coeff to dest-electrodes
    
    # Based on:
#  [1] F. Perrin, J. Pernier, O. Bertrand, and J. F. Echallier, 
#       “Spherical splines for scalp potential and current density mapping,” 
#      Electroencephalogr Clin Neurophysiol, vol. 72, no. 2, pp. 184–187, Feb. 1989.
#  [2] T. C. Ferree, “Spherical Splines and Average Referencing in Scalp 
#      Electroencephalography,” Brain Topogr, vol. 19, no. 1–2, pp. 43–52, Oct. 2006.
    
    # TODO []: Special case when mapping to the same set of electrodes
    if nargin < 2 or isempty(dest):
        dest=copy(src)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:31
    
    if nargin < 3 or isempty(lambda_):
        lambda_=0.0001
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:32
    
    if nargin < 4 or isempty(order):
        order=4
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:33
    
    if nargin < 5 or isempty(type_):
        type_='spline'
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:34
    
    if nargin < 6 or isempty(tol):
        tol=1e-09
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:35
    
    if nargin < 7 or isempty(verb):
        verb=1
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:36
    
    # map the positions onto the sphere
    src=repop(src,'./',sqrt(sum(src ** 2)))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:39
    dest=repop(dest,'./',sqrt(sum(dest ** 2)))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:40
    #calculate the cosine of the angle between the new and old electrodes. If
#the vectors are on top of each other, the result is 1, if they are
#pointing the other way, the result is -1
    cosSS=dot(src.T,src)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:45
    
    cosDS=dot(dest.T,src)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:46
    
    # Compute the interpolation matrix to tolerance tol
# N.B. this puts 1 symetric basis function on each source location
    Gss=interpMx(cosSS,order,tol,verb)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:50
    
    Gds,Hds=interpMx(cosDS,order,tol,verb,nargout=2)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:51
    
    # Include the regularisation
    if lambda_ > 0:
        Gss=Gss + dot(lambda_,eye(size(Gss)))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:54
    
    # Compute the mapping to the polynomial coefficients space # [nSrc+1 x nSrc+1]
# N.B. this can be numerically unstable so use the PINV to solve..
    muGss=1
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:58
    
    #C = [      Gss            muGss*ones(size(Gss,1),1)];
    C=concat([[Gss,dot(muGss,ones(size(Gss,1),1))],[dot(muGss,ones(1,size(Gss,2))),0]])
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:60
    iC=pinv(C)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:62
    # Compute the mapping from source measurements and positions to destination positions
    if (strcmp(lower(type_),'spline')):
        W=dot(concat([Gds,multiply(ones(size(Gds,1),1),muGss)]),iC(arange(),arange(1,end() - 1)))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:66
    else:
        if (strcmp(lower(type_),'splinecomp')):
            W=iC(arange(),arange(1,end() - 1))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:68
        else:
            if (strcmp(lower(type_),'splinecar')):
                W=dot(Gds,iC(arange(1,end() - 1),arange(1,end() - 1)))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:70
            else:
                if (strcmp(lower(type_),'slap')):
                    W=dot(Hds,iC(arange(1,end() - 1),arange(1,end() - 1)))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:72
    
    return W,Gss,Gds,Hds
    #--------------------------------------------------------------------------
    
@function
def interpMx(cosEE=None,order=None,tol=None,verb=None,*args,**kwargs):
    varargin = interpMx.varargin
    nargin = interpMx.nargin

    # compute the interpolation matrix for this set of point pairs
# by evaluating the legendre polynomial recurrence equations
    if nargin < 3 or isempty(tol):
        tol=1e-10
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:79
    
    if nargin < 4 or isempty(verb):
        verb=0
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:80
    
    G=zeros(size(cosEE))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:81
    H=zeros(size(cosEE))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:81
    # precompute some stuff
    for n in arange(1,500).reshape(-1):
        n2pn[n]=(dot(n,n) + n) ** order
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:83
    
    if verb > 0 and numel(cosEE) > 1000:
        fprintf('sspline:')
    
    for i in arange(1,numel(cosEE)).reshape(-1):
        x=cosEE(i)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:86
        n=1
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:87
        Pns1=1
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:87
        Pn=copy(x)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:87
        tmp=(dot((dot(2,n) + 1),Pn)) / ((dot(n,n) + n) ** order)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:88
        G[i]=tmp
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:89
        H[i]=dot((dot(n,n) + n),tmp)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:90
        oGi=copy(inf)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:91
        dG=abs(G(i))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:91
        oHi=copy(inf)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:91
        dH=abs(H(i))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:91
        for n in arange(2,500).reshape(-1):
            Pns2=copy(Pns1)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:93
            Pns1=copy(Pn)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:93
            Pn=(dot(dot((dot(2,n) - 1),x),Pns1) - dot((n - 1),Pns2)) / n
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:93
            oGi=G(i)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:94
            oHi=H(i)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:94
            tmp=(dot((dot(2,n) + 1),Pn)) / n2pn(n)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:95
            G[i]=G(i) + tmp
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:96
            H[i]=H(i) + dot((dot(n,n) + n),tmp)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:97
            dG=(abs(oGi - G(i)) + dG) / 2
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:98
            dH=(abs(oHi - H(i)) + dH) / 2
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:98
            #fprintf('#d) dG =#g \t dH = #g\n',n,dG,dH);#abs(oGi-G(i)),abs(oHi-H(i)));
            if (dG < tol and dH < tol):
                break
        if verb > 0 and numel(cosEE) > 1000:
            textprogressbar(i,numel(cosEE))
    
    if verb > 0 and numel(cosEE) > 1000:
        fprintf('\n')
    
    G=G / (dot(4,pi))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:107
    H=H / (dot(4,pi))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:108
    return G,H
    #--------------------------------------------------------------------------
    
@function
def testCase(*args,**kwargs):
    varargin = testCase.varargin
    nargin = testCase.nargin

    src=randn(3,30)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:112
    src[3,arange()]=abs(src(3,arange()))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:112
    src=repop(src,'./',sqrt(sum(src ** 2)))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:112
    
    dest=rand(3,20)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:113
    dest[3,arange()]=abs(dest(3,arange()))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:113
    dest=repop(dest,'./',sqrt(sum(dest ** 2)))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:113
    
    clf
    scatPlot(src,'b.')
    Cname,latlong,xy,xyz=readCapInf('cap32',nargout=4)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:116
    src=copy(xyz)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:116
    dest=copy(xyz)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:116
    W=sphericalSplineInterpolate(src,dest)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:118
    W=sphericalSplineInterpolate(src,dest,[],[],'slap')
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:119
    W=sphericalSplineInterpolate(src,dest,[],[],'splineCAR')
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:120
    W=sphericalSplineInterpolate(src,dest,[],[],'splineComp')
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:121
    clf
    imagesc(W)
    clf
    jplot(src(arange(1,2),arange()),W.T,'clim','cent0')
    colormap('ikelvin')
    clickplots
    z=jf_load('eeg/vgrid/nips2007/1-rect230ms','jh','flip_rc_sep')
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:126
    z=jf_retain(z,'dim','ch','idx',concat([z.di(1).extra.iseeg]))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:127
    lambda_=0
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:128
    order=4
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:128
    chPos=concat([z.di(1).extra.pos3d])
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:129
    incIdx=arange(1,size(dest,2) - 3)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:130
    exIdx=setdiff(arange(1,size(dest,2)),incIdx)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:130
    
    W=sphericalSplineInterpolate(chPos(arange(),incIdx),chPos,lambda_,order)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:131
    
    clf
    imagesc(W)
    clf
    jplot(chPos(arange(),incIdx),W(exIdx,arange()).T)
    # compare estimated with true
    X=z.X(arange(),arange(),2)
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:135
    Xest=dot(W,z.X(incIdx,arange(),2))
# /Users/jdrf/source/matfiles/numutil/sphericalSplineInterpolate.m:136
    clf
    mcplot(concat([[X(exIdx(1),arange())],[Xest(exIdx(1),arange())]]).T)
    clf
    subplot(211)
    mcplot(X.T)
    subplot(212)
    mcplot(Xest.T)