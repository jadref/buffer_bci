import numpy as np

def sphericalSplineInterpolate(src,dest=None,lambda_=.0001,order=4,type_="spline",tol=1e-9,verb=0):
    '''interpolate matrix for spherical interpolation based on Perrin89
     W = sphericalSplineInterpolate(src,dest,lambda,order,type,tol)
    Inputs:
     src    - [3 x N] old electrode positions
     dest   - [3 x M] new electrode positions, =src if not given.
     lambda - [float] regularisation parameter for smoothing the estimates (1e-5)
     order  - [float] order of the polynomial interplotation to use (4)
     type - [str] one of;                                         ('spline')
             'spline' - spherical Spline 
             'splineCAR' - as for spline but without the constant term
                  as described in [2] this approx. the signal referenced at infinity
             'slap'   - surface Laplician (aka. CSD)             
     tol    - [float] tolerance for the legendre poly approx        (1e-7)
    Outputs:
     W      - [M x N] linear mapping matrix between old and new co-ords
     Gss    - [N x N] weight matrix from sources to sources
     Gds    - [M x N] weight matrix from sources to destinations
     Hds    - [M x N] lapacian deriv matrix from source coeff to dest-electrodes
    
    Based on:
    [1] F. Perrin, J. Pernier, O. Bertrand, and J. F. Echallier, 
       “Spherical splines for scalp potential and current density mapping,” 
      Electroencephalogr Clin Neurophysiol, vol. 72, no. 2, pp. 184-187, Feb. 1989.
    [2] T. C. Ferree, “Spherical Splines and Average Referencing in Scalp 
      Electroencephalography,” Brain Topogr, vol. 19, no. 1-2, pp. 43-52, Oct. 2006.
    '''

    if not isinstance(src,np.ndarray):
        raise Exception("src should be a numpy array of electrode coordinates")
    # map the positions onto the sphere
    src =src/np.sqrt(np.sum(src ** 2,0,keepdims=True))
    dest=dest/np.sqrt(np.sum(dest ** 2,0,keepdims=True))
    #calculate the cosine of the angle between the new and old electrodes. If
    #the vectors are on top of each other, the result is 1, if they are
    #pointing the other way, the result is -1
    cosSS=np.dot(src.T,src)
    cosDS=np.dot(dest.T,src)
    
    # Compute the interpolation matrix to tolerance tol
    # N.B. this puts 1 symetric basis function on each source location
    Gss,_=interpMx(cosSS,order,tol,verb)
    Gds,Hds=interpMx(cosDS,order,tol,verb)
    
    # Include the regularisation
    if lambda_ > 0:
        Gss=Gss + lambda_*np.eye(Gss.shape[0])
    
    # Compute the mapping to the polynomial coefficients space # [nSrc+1 x nSrc+1]
    # N.B. this can be numerically unstable so use the PINV to solve..
    muGss=1
                   
    #C = [      Gss            muGss*ones(size(Gss,1),1);
    #      muGss*ones(1,size(Gss,2))     0];
    C=np.concatenate([
        np.concatenate([Gss,        muGss*np.ones((Gss.shape[0],1))],1),
        np.concatenate([muGss*np.ones((1,Gss.shape[1])),  np.zeros((1,1))],1)
    ],0)
    iC=np.linalg.pinv(C)
    # Compute the mapping from source measurements and positions to destination positions
    if type_.upper() == 'SPLINE' :
        W=np.dot(np.concatenate([Gds, np.ones((Gds.shape[0],1))*muGss],1),iC[:,:-1])
    elif type_.upper() == 'SPLINECOMP' :
        W=iC[:,:-1]
    elif type_.upper() == 'SPLINECAR' :
        W=np.dot(Gds,iC[:-1,:-1])
    elif type_.upper() == 'SLAP' :
        W=np.dot(Hds,iC[:-1,:-1])
    return W,Gss,Gds,Hds
    
def interpMx(cosEE,order=4,tol=1e-10,verb=0):
    G=np.zeros(cosEE.shape)
    H=np.zeros(cosEE.shape)
    # precompute some stuff
    n2pn=[(n*n + n)**order for n in range(500)]
    
    for i in range(cosEE.shape[0]):
        for j in range(cosEE.shape[1]):
            x   = cosEE[i,j]
            n   = 1
            Pns1= 1
            Pn  = x
            tmp = ((2*n + 1)*Pn) / ((n*n + n) ** order)
            G[i,j]= tmp
            H[i,j]= (n*n + n)*tmp
            oGi = np.inf
            dG  = abs(G[i,j])
            oHi = np.inf
            dH  = abs(H[i,j])
            for n in range(2,500):
                Pns2= Pns1
                Pns1= Pn
                Pn  = (((2*n - 1)*x*Pns1) - (n - 1)*Pns2) / n
                oGi=G[i,j]
                oHi=H[i,j]
                tmp=((2*n + 1)*Pn) / n2pn[n]
                G[i,j]=G[i,j] + tmp
                H[i,j]=H[i,j] + (n*n + n)*tmp
                dG=(abs(oGi - G[i,j]) + dG) / 2
                dH=(abs(oHi - H[i,j]) + dH) / 2
                if verb>0 : print('%d) dG =%g \t dH = %g\n'%(n,dG,dH));
                #abs(oGi-G(i)),abs(oHi-H(i)));
                if (dG < tol and dH < tol):
                    break
    
    G=G / 4*np.pi
    H=H / 4*np.pi
    return G,H
    #--------------------------------------------------------------------------
    
if __name__ == "__main__":
    src=np.random.randn(3,30)    
    src[-1,:]=abs(src[-1,:])
    src=src / np.sqrt(np.sum(src**2,axis=0,keepdims=True))
    
    dest=np.random.rand(3,20)
    dest[-1,:]=abs(dest[-1,:])
    dest=dest / np.sqrt(np.sum(dest ** 2,axis=0,keepdims=True))

    cosSS = np.dot(src.T,src)
    interpMx(cosSS)
    
    W,_,_,_=sphericalSplineInterpolate(src,dest)
    W,_,_,_=sphericalSplineInterpolate(src,dest,type_='slap')
    W,_,_,_=sphericalSplineInterpolate(src,dest,type_='splineCAR')
    W,_,_,_=sphericalSplineInterpolate(src,dest,type_='splineComp')

    
    
    import matplotlib as plt
    plt.clf()
    plt.scatPlot(src,'b.')
    Cname,latlong,xy,xyz=readCapInf('cap32')
    src =copy(xyz)
    dest=copy(xyz)
    W=sphericalSplineInterpolate(src,dest)
    W=sphericalSplineInterpolate(src,dest,type_='slap')
    W=sphericalSplineInterpolate(src,dest,type_='splineCAR')
    W=sphericalSplineInterpolate(src,dest,type_='splineComp')
    clf
    imagesc(W)
