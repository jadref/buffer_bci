import numpy as np

def packBoxes(Xs,Ys):
    """Give a set of X,Y positions pack non-overlapping rectangular boxes
     rX,rY=packBoxes(Xs,Ys)
     Inputs:
     Xs - [N x 1] x positions
     Ys - [N x 1] y positions
     Outputs:
     rX - [N x 1] x radius
     rY - [N x 1] y radius
     """
    if type(Xs) is np.ndarray :
        pass
    else:
        if Xs is list :
            Xs = np.asarray(Xs)
        else:
            raise TypeError('Only for lists/arrays')
    if not type(Ys) is np.ndarray :
        if Ys is list :
            Ys = np.asarray(Ys)
        else:
            raise TypeError('Only for lists/arrays')
    Xs=Xs.ravel()
    Ys=Ys.ravel()
    # ensure given as floats
    if np.issubdtype(Xs.dtype,np.integer):
        Xs=Xs.astype(np.float32)
    if np.issubdtype(Ys.dtype,np.integer):
        Ys=Ys.astype(np.float32) 
            
    N=len(Xs)
    # Now, Find the all plots pairwise distance matrix, w.r.t. this scaling
    Dx=np.abs(Xs[np.newaxis] - Xs[np.newaxis].T) #Note the 'hack' to transpose a 1d array
    Dy=np.abs(Ys[np.newaxis] - Ys[np.newaxis].T)
    rX=np.zeros(N) 
    rY=np.zeros(N)
    for i in range(0,N):
        Dx[i,i]=np.inf
        Dy[i,i]=np.inf
        rX[i]=np.min(Dx[Dx[:,i] >= Dy[:,i],i]) / 2
        rY[i]=np.min(Dy[Dx[:,i] <= Dy[:,i],i]) / 2
    
    # Unconstrained boundaries are limited by the max/min of the constrained ones
    # or .5 if nothing else...
    if np.any(np.isinf(rX)):
        if np.all(np.isinf(rX)):
            rX[:]=0.5
        else:
            unconsX=np.isinf(rX)
            rX[unconsX]=0
            minX=np.min(Xs - rX)
            maxX=np.min(Xs + rX)
            rX[unconsX]=np.min(np.concatenate(maxX - Xs[unconsX],Xs[unconsX] - minX),0)
# packBoxes.m:31
    
    if np.any(np.isinf(rY)):
        if np.all(np.isinf(rY)):
            rY[:]=.5
        else:
            unconsY=np.isinf(rY)
            rY[unconsY]=0
            minY=np.min(Ys - rY)
            maxY=np.min(Ys + rY)
            rY[unconsY]=np.min(np.concatenate(maxY - Ys[unconsY],Ys[unconsY] - minY),0)
    
    
    return rX,rY


import matplotlib
def testCases():
    Xs=np.random.rand(10)*10 #linspace(0,10,10)
    Ys=np.random.rand(10)*10 #linspace(0,10,10) 
    rX,rY=packBoxes(Xs,Ys)

    a=matplotlib.pyplot.axes()
    a.set(xlim=[0,10],ylim=[0,10])
    for i in range(len(Xs)):
        a.add_patch(matplotlib.patches.Rectangle((Xs[i]-rX[i],Ys[i]-rY[i]),2*rX[i],2*rY[i]))
