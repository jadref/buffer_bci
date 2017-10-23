import numpy as np
import matplotlib.pyplot as plt
from packBoxes import *

def posplot(XYs,Idx=None,Xs=None,Ys=None,interplotgap=.003,plotsposition=[0.05,0.05,.93,.90],scaling='any',sizes='any',postype='position',emptySize=.05,sizeOnly=False,*args):
    """  
    Function to generate sub-plots at given 2-d positions
    
    # [hs,(Xs,Ys),(rX,rY)]=posPlot(XYs[,options])
    # Inputs:
    #  Xs -- X (horz) positions of the plots [1 x N]
    #  Ys -- Y (vert) positions of the plots [1 x N]
    # XYs -- X,Y positions of the plots      [2 x N]
    # Idx -- subplot to make current         [1 x 1] or []   (1)
    # Options
    #  scaling -- do we preserve the relative scaling of x y axes?
    #             'none': don't preserver, 'square' : do preserve
    #  sizes   -- do we constrain the plots to be the same size?
    #             'none': no size constraint, 'equal': all plots have same x/y size
    #          -- Everything else is treated as an option for axes
    #  plotsposition-- [4 x 1] vector of the figure box to put the plots: [x,y,w,h]
    #                  ([0 0 1 1])
    # Outputs:
    #  hs -- if output is requested this is the set of sub-plot handles, 
    #        [N x 1] if Idx==[] or the [1x1] handle of the Idx'th plot if specified
    #  Xs,Ys,Rx,Ry -- position of the plots
    """
    
    if len(plotsposition) == 1:
        plotsposition[0:3]=plotsposition
    elif not (len(plotsposition) == 0 or len(plotsposition)==4):
        error('Figure boundary gap should be 1 or 4 element vector')
    
    if not type(interplotgap) is np.ndarray :
        tmp          = interplotgap
        interplotgap = np.zeros((4,1))
        interplotgap[0:3]=tmp
    elif len(interplotgap) == 1:
        tmp          = interplotgap
        interplotgap = np.zeros((4,1))        
        interplotgap[0:3]=tmp
    elif not (len(interplotgap) == 0 or len(interplotgap)==4):
        error('Interplot gap should be 1 or 4 element vector')

    # extract the separate Xs, Ys from XYs
    if not XYs is None:
        if not type(XYs) is np.ndarray: # assume list, convert to np.ndarray
            XYs = np.array(XYs)
            if XYs.ndim==1 : XYs=XYs.reshape(-1,1) # ensure 2d
            if np.size(XYs,0)!=2 and np.size(XYs,1)==2 :
                 XYs = XYs.T;
        Xs = XYs[0,:]
        Ys = XYs[1,:]
        
    if len(Ys) != len(Xs):
        error('Xs and Ys *must* have same number of elements')
    
    if not Idx is None and not Idx in range(len(Xs)):
        error('Idx greater than the number of sub-plots')
    
    Xs=Xs.reshape(1,-1).T # enusre 2-d row vector [nPlot x 1]
    Ys=Ys.reshape(1,-1).T # enusre 2-d row vector [nPlot x 1]   
    N=len(Xs)
    # Compute the radius between the points
    rX,rY=packBoxes(Xs,Ys)
    if sizes == 'equal':
        rX[:]=np.min(rX)
        rY[:]=np.min(rY)
    
    rX=np.tile(rX[:,np.newaxis],(1,2)) # allow different left/right radii [nPlot x 2]
    rY=np.tile(rY[:,np.newaxis],(1,2))
    
    # Next compute scaling for the input to the unit 0-1 square, centered on .5
    minX=np.min(Xs - rX[:,0])
    maxX=np.max(Xs + rX[:,1])
    
    minY=np.min(Ys - rY[:,0])
    maxY=np.max(Ys + rY[:,1])
    
    W=maxX - minX
    W=W / plotsposition[2]
    if W <= 0:
        W=1
    
    H=maxY - minY
    H=H / plotsposition[3]
    if H <= 0:
        H=1
    
    if not scaling is None and scaling.lower()=='square':
        W=max(W,H)
        H=max(W,H)
    
    Xs=(Xs - (maxX + minX) / 2) / W
    rX=rX / W
    Xs=Xs + plotsposition[0] + .5*plotsposition[2]
    Ys=(Ys - (maxY + minY) / 2) / H
    rY=rY / H
    Ys=Ys + plotsposition[1] + .5*plotsposition[3]
    # subtract the inter-plot gap if necessary.
    rX[:,0]=rX[:,0] - interplotgap[0]
    rX[:,1]=rX[:,1] - interplotgap[1]
    rY[:,0]=rY[:,0] - interplotgap[2]
    rY[:,1]=rY[:,1] - interplotgap[3]
    
    # Check if this is a reasonable layout
    if emptySize > 0 and (np.any(rX <= 0) or
                          np.any(rY <= 0) or
                          np.any(np.isnan(rY)) or
                          np.any(np.isnan(rX))):
        print('Not enough room between points to make plot')
        rX[rX <= 0 | np.isnan(rX)]=emptySize
        rY[rY <= 0 | np.isnan(rY)]=emptySize#(min(len(emptySize),1))
    
    # generate all subplots if handles wanted
    hs=[]
    if not sizeOnly:
        if Idx is None: 
            for i in range(0,N):
                pos=[Xs[i,0] - rX[i,0], Ys[i,0] - rY[i,0], np.sum(rX[i,:]), np.sum(rY[i,:])]
                h=plt.axes(pos,*args)
                hs.append(h)
        else: # only make the Idx'th plot
            pos=(Xs[Idx,0] - rX[Idx,0],Ys[Idx,0] - rY[Idx,0],
                            np.sum(rX[Idx,:]),np.sum(rY[Idx,:]))
            hs=plt.axes(pos,*args)
    if not Idx is None:
        Xs=Xs[Idx]
        Ys=Ys[Idx]
        rX=sum(rX[Idx,:])
        rY=sum(rY[Idx,:])
    
    return (hs,(Xs,Ys),(rX,rY))
    #----------------------------------------------------------------------------
    
def testCase():
    import posplot
    clf;posplot.posplot([0,0])
    hs=posplot.posplot(cat(1,2,3),cat(2,2,2))
    posplot.posplot(cat([1,2,3],[2,2,2]))
    clf
    h=posplot.posplot(cat(1,2,3),cat(1,2,3))
    clf
    h=posplot(rand(10,1),rand(10,1))
    clf
    h=posplot.posplot(rand(10,1),rand(10,1),[],sizes='any')
    clf
    h=posplot.posplot(cat(1,2,3),cat(1,1.5,2),[],sizes='any')
    clf
    h=posplot.posplot(cat(0.2,0.6,0.7),cat(0.5,0.4,0.45),[],sizes='any')
    clf
    h=posplot.posplot(cat(0,sin(arange(0,dot(dot(2,pi),0.99),dot(2,pi) / 10))),cat(0,cos(arange(0,dot(dot(2,pi),0.99),dot(2,pi) / 10))),[],sizes='any')
    for i in arange(1,11).reshape(-1):
        posplot.posplot(cat(0,sin(arange(0,dot(dot(2,pi),0.99),dot(2,pi) / 10))),cat(0,cos(arange(0,dot(dot(2,pi),0.99),dot(2,pi) / 10))),i,sizes='any')
        #plot(sin(arange(0,dot(2,pi),dot(2,pi) / 10)))
    
