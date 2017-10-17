import numpy as np
import matplotlib.pyplot as plt
from posplot import *

def image3d(X,dim=1,plotPos=None,Xvals=None,Yvals=None,Zvals=None,*args):
"""
 plot 3d matrix in the image style
 
  h=image3d(A,dim,....)

 Inputs:
  A   -- the ndarray to plot
  dim -- the dimension of A along which to slice for plotting
 Options:
  Xvals    -- values for each element of A along 1st (X) dimension
  Yvals    -- values for each element of A along 2st (Y) dimension
  Zvals    -- values for each element of A along 3st (Z) dimension
  plotPos  -- [size(A,dim) x 4] set of [x,y] positions to plot the slices

(Unsupported Options):
  handles  -- [size(A,dim) x 1] set of axes handles to plot the slices
  layout   -- [2 x 1] width x height in subplots
  xlabel   -- str with the label (i.e. dimension name, e.g. 'ch') for the x (dim 1) bin values ('')
  ylabel   -- str with the label (i.e. dimension name, e.g. 'time') for the y (dim 2) bin values ('')
  zlabel   -- str with the label (i.e. dimension name, e.g. 'epoch')for the z (dim 3) bin values ('')
  colorbar -- [1x1] logical, put on a colorbar/legend (true for image dispType)
  legend   -- [1x1] logical, put a legend on the plot (true for plot dispType)
                {'se','sw','ne','nw'} -- where to put the legend
  clim     -- type of axis limits to use, [2x1] limits, 'centf' centered on f, 'minmax' data range
               empty clim means let each plot have it's own color scaling
  showtitle-- [bool] show title on each plot                      (true)
  clabel   -- str with the label for the colors
  ticklabs -- {'all','none','SW','SE','NW','NE'} put tick labels on plots
              at these locations ('all')
  varargin -- addition properties of the plot to set
  disptype -- type of plot to draw, {'image','imaget','plot'}
                image  -- normal image
                imaget -- image with x/y axes swapped
                plot   -- line plot
                mcplot -- multi-channel plot
                mcplott-- multi-channel plot, with x/y axes swapped
                function_name -- call user supplied function to draw the
                      plot. Call mode is:
                      function_name(xvals,yvals,data_matrix,...
                                    xticklabs,yticklabs,xlabel,ylabel,clabel)
  plotopts -- options to pass to the display function ([])
  plotPosOpts -- options to pass to posPlots (if used)
                 (struct('sizes','equal','plotsposition',[.05 .08 .91 .88],'postype','position'))
  titlepos -- [x y width] title position relative to the plot  ([.5 1 1])
 Outputs:
  h   -- the handles of the generated plots
"""

if not type(X) is np.ndarray:
    raise TypeError('Only defined for numpy ndarrays current')

#add/remove dimensions to make it 3d
if X.ndim!=3:
    if X.ndim<3:
        X=X.reshape(X.shape+(1,)*(3-X.ndim)) # add dims to back
    elif X.ndim>3:
        X=X.reshape(X.shape[0:1]+(-1,))
if dim<0 or dim>3 :
    raise ValueError('dim outside valid range')

nPlot=X.size[dim]
        
# pre-build the axes
fig = plt.gcf
if not plotPos is None:
    h = posplot(plotPos)
else:
    if layout is None: # compute layout
        w = math.ceil(math.sqrt(nPlot))
        h = math.ceil(nPlot / w)
        layout = (w,h)
    fig,h = plt.subplots(ncols=layout[0],nrows=layout[1])


# loop over the plots making them
for pi in range(0,nPlot):
    # extract the data for this plot
    if dim==1 :        Xpi = X[pi,:,:].reshape((X.size[2],-1))
    elif dim==2:       Xpi = X[:,pi,:].reshape((X.size[1],-1))
    elif dim==3:       Xpi = X[:,:,pi].reshape((X.size[1],-1))
    
