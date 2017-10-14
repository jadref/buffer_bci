import numpy as np
import matplotlib.pyplot as plt

def posplot(Xs=None,Ys=None,Idx=1,XYs=None,interplotgap=.003,plotsposition=[0.05,0.05,.93,.90],scaling='any',sizes='any',postype='position',emptySize=.05,*args):
    """  Function to generate sub-plots at given 2-d positions
    
    # [hs]=posPlot(Xs,Ys,Idx[,options])
    # OR
    # [hs]=posPlot(XYs,Idx[,options])
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
        plotsposition[1:4]=plotsposition
    elif not (len(plotsposition) == 0 or len(plotsposition)==4):
        error('Figure boundary gap should be 1 or 4 element vector')
    
    if not type(interplotgap) is np.ndarray :
        interplotgap = np.zeros((4,1))
        interplotgap[0:3]=interplotgap
    elif len(interplotgap) == 1:
        interplotgap = np.zeros(4,1)        
        interplotgap[0:3]=interplotgap
    elif not (len(interplotgap) == 0 or len(interplotgap)==4):
        error('Interplot gap should be 1 or 4 element vector')
    
    if len(Ys) != len(Xs):
        error('Xs and Ys *must* have same number of elements')
    
    if not Idx is None and not Idx in range(len(Xs)):
        error('Idx greater than the number of sub-plots')
    
    Xs=ravel(Xs)[np.newaxis] # enusre 2-d row vector [1,nPlot]
    Ys=ravel(Ys)[np.newaxis] # enusre 2-d row vector [1,nPlot]   
    N=numel(Xs)
    # Compute the radius between the points
    rX,rY=packBoxes(Xs,Ys,nargout=2)
    if sizes == 'equal':
        rX[:]=np.min(rX)
        rY[:]=np.min(rY)
    
    rX=np.concatenate((rX,rX)) # alow different left/right radii
    rY=np.concatenate((rY,rY))
    
    # Next compute scaling for the input to the unit 0-1 square, centered on .5
    minX=np.min(Xs - rX[:,1])
    maxX=np.max(Xs + rX[:,2])
    
    minY=np.min(Ys - rY[:,1])
    maxY=np.max(Ys + rY[:,2])
    
    W=maxX - minX
    W=W / plotsposition[3]
    if W <= 0:
        W=1
    
    H=maxY - minY
    H=H / plotsposition[4]
    if H <= 0:
        H=1
    
    if not scaling is None and scaling.lower()=='square':
        W=max(W,H)
        H=max(W,H)
    
    Xs=(Xs - (maxX + minX) / 2) / W
    rX=rX / W
    Xs=Xs + plotsposition[1] + .5*plotsposition[3]
    Ys=(Ys - (maxY + minY) / 2) / H
    rY=rY / H
    Ys=Ys + plotsposition[2] + .5*plotsposition[4]
    # subtract the inter-plot gap if necessary.
    rX[:,1]=rX[:,1] - interplotgap[1]
    rX[:,2]=rX[:,2] - interplotgap[2]
    rY[:,1]=rY[:,1] - interplotgap[3]
    rY[:,2]=rY[:,2] - interplotgap[4]
    
    # Check if this is a reasonable layout
    if emptySize > 0 and (np.any(np.ravel(rX) <= 0) or
                          np.any(ravel(rY) <= 0) or
                          np.any(isnan(ravel(rY))) or
                          np.any(isnan(ravel(rX)))):
        print('Not enough room between points to make plot')
        rX[rX <= 0 | np.isnan(rX)]=emptySize(1)
        rY[rY <= 0 | np.isnan(rY)]=emptySize(min(len(emptySize),2))
    
    # generate all subplots if handles wanted
    hs=[]
    if not sizeOnly:
        if Idx is None: 
            for i in range(1,N):
                hs[i]=plt.axes((Xs[i] - rX[i,1],Ys[i] - rY[i,1]),
                               np.sum(rX[i,:]),np.sum(rY[i,:]),args)
        else: # only make the Idx'th plot
            hs[i]=plt.axes((Xs[Idx] - rX[Idx,1],Ys[Idx] - rY[Idx,1]),
                           np.sum(rX[Idx,:]),np.sum(rY[Idx,:]),args)
    if not Idx is None:
        Xs=Xs[Idx]
        Ys=Ys[Idx]
        rX=sum(rX[Idx,:])
        rY=sum(rY[Idx,:])
    
    return (hs,Xs,Ys,rX,rY)
    #----------------------------------------------------------------------------
    
def testCase():
    from posplot import *
    clf;posplot([0,0])
    hs=posplot(cat(1,2,3),cat(2,2,2))
# posplot.m:100
    posplot(cat([1,2,3],[2,2,2]))
    clf
    h=posplot(cat(1,2,3),cat(1,2,3))
# posplot.m:102
    clf
    h=posplot(rand(10,1),rand(10,1))
# posplot.m:103
    clf
    h=posplot(rand(10,1),rand(10,1),[],sizes='any')
# posplot.m:104
    clf
    h=posplot(cat(1,2,3),cat(1,1.5,2),[],sizes='any')
# posplot.m:105
    clf
    h=posplot(cat(0.2,0.6,0.7),cat(0.5,0.4,0.45),[],sizes='any')
# posplot.m:107
    clf
    h=posplot(cat(0,sin(arange(0,dot(dot(2,pi),0.99),dot(2,pi) / 10))),cat(0,cos(arange(0,dot(dot(2,pi),0.99),dot(2,pi) / 10))),[],sizes='any')
# posplot.m:109
    for i in arange(1,11).reshape(-1):
        posplot(cat(0,sin(arange(0,dot(dot(2,pi),0.99),dot(2,pi) / 10))),cat(0,cos(arange(0,dot(dot(2,pi),0.99),dot(2,pi) / 10))),i,sizes='any')
        plot(sin(arange(0,dot(2,pi),dot(2,pi) / 10)))
    
