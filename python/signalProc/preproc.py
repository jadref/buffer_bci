import scipy.signal 
import numpy
from math import ceil
import collections
from functools import reduce

def detrend(data, dim=1, type="linear"):
    '''Removes trends from the data.
    
    Applies the scipy.signal.detrend function to the data, this numpy function
    offers to types of detrending:
    
    linear - the result of a linear least-squares fit to data is subtracted 
    from the data.
    constant - the mean of the data is subtracted from the data.
    
    Parameters
    ----------
    data : list of datapoints (numpy arrays) or a single numpy array.
    dim : the axis along which detrending needs to be applied
    type : a string that indicates the type of detrending should either 
    be "linear" or "constant"
    
    Returns
    -------
    out : a clone of data on wich the detrending algorithm has been applied
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> data = preproc.detrend(data,type="constant")
    >>> data = bufhelp.gatherdata("start",10,"stop")
    >>> data = preproc.detrend(data)
    '''
                
    if not isinstance(type,str):
        raise Exception("type is not a string.")
        
    if type!="linear" and type!="constant":
        raise Exception("type should either be linear or constant")
            
    if not isinstance(data,numpy.ndarray):
        X = concatdata(data)
    elif isinstance(data,numpy.ndarray):
        X = data
    else:
        raise Exception("data should be a numpy array or list of numpy arrays.")
    
    X = scipy.signal.detrend(X, axis=dim, type=type)
    
    if not isinstance(data,numpy.ndarray):
        return rebuilddata(X,data)
    else:
        return X



def spatialfilter(data, type="car",whitencutoff=1e-15, dim=1):
    '''Spatial filter for a list of datapoints.
    
    Applies a spatial filter to the data offers two types:
    
    car    - the common average reference
    whiten - Whitening transform
    
    Both are based on eegtools, see references.
    
    Parameters
    ----------
    data : list of datapoints (numpy arrays) or a single numpy array. [samples x channels x trials]
    type : a string that indicates the type of spatial filter should either 
    be "car" or "whitten"
    whittencutoff : Only used with the whitten transform, it specifies the 
    cut-off value as the fraction of the largest eigenvalue of D.
    dim : the dimension along which the spatial filter is to be applied  (1)
    
    Returns
    -------
    out : a clone of data on wich a spatial filter has been applied
    
    References
    ----------  
    https://github.com/breuderink/eegtools/blob/master/eegtools/spatfilt.py
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> data = preproc.spatialfilter(data, type="whiten") #train
    >>> data = bufhelp.gatherdata("start",10,"stop")
    >>> data = preproc.spatialfilter(data) #apply
    '''
        
    if not isinstance(type,str):
        raise Exception("type is not a string.")

    if not isinstance(data,numpy.ndarray):
        X = concatdata(data)
    elif isinstance(data,numpy.ndarray):
        X = data
    else:
        raise Exception("data should be a numpy array or list of numpy arrays.")
        
    if type=="car":
        
        X = X - numpy.mean(X,axis=0,keepdims=True) #numpy.dot(X,numpy.eye(X.shape[0])-(1.0/X.shape[0]))
        
    elif type=="whiten":
        
        if not isinstance(whitencutoff, (int,float)):
            raise Exception("whitencutoff is not a number.") 
            
        C = numpy.cov(X.reshape(X.shape[0],-1))
        e, E = numpy.linalg.eigh(C)
        keep = [ v > numpy.max(e)*whitencutoff for v in e ]
        e=e[keep]
        E=E[:,keep]
        isqrte = numpy.array([v**-.5 for v in e ])
        W = numpy.dot(E,isqrte*E.T)
        X = numpy.dot(W,X.reshape(X.shape[0],-1)).reshape(X.shape)
    
    if not isinstance(data,numpy.ndarray):
        return rebuilddata(X,data)
    else:
        return X

    
def fouriertransform(data, dim=0, fSample=1, posFreq=False):
    '''Fourier transform for a list of datapoints.
    
    Transforms the data from the time domain to the frequency domain. Returns
    a power spectrum.
    
    Parameters
    ----------
    data : list of datapoints (numpy arrays) or a single numpy array.
    dim : the dimension over which the fourier filter needs to be applied  (0)
    fSample ; the sampling frequency of the data                           (1)
    posFreq : only return the values for the positive frequencies          (False)
    
    Returns
    -------
    out : (ft,freqs) the fourier transform of the data and the frequency bins
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> hdr = ftc.getHeader()
    >>> data = preproc.fouriertransform(data, fSample=hdr.fSample)
    >>> data = bufhelp.gatherdata("start",10,"stop")
    >>> data = preproc.fouriertransform(data, fSample=bufhelp.fSample)
    '''
        
    if not isinstance(dim, int):
        raise Exception("dim is not a int.")   

    if isinstance(fSample,int): fSample=float(fSample) 
    if not isinstance(fSample,float):
        raise Exception("fSample is not float")
    
    if not isinstance(data,numpy.ndarray):
        ft = clonelist(data)
        freqs = numpy.fft.fftfreq(data.shape[dim], 1.0/fSample)
        for k in range(0,len(data)):            
            ft[k] = numpy.fft.fft(ft[k], axis=dim)
            if posFreq :
                posfreqIdx = [i for i in numpy.argsort(freqs) if freqs[i] >= 0]
                # build an index expression to get the subset of data we want
                idx = [ slice(0,ft[k].shape[i]) for i in range(len(ft[k].shape))]
                idx[dim] = posfreqIdx
                ft[k]  = ft[k](tuple(idx))
                freqs=freqs[posfreqIdx]
            
        return 
    elif isinstance(data,numpy.ndarray):
        ft = numpy.fft.fft(data, axis=dim)
        freqs = numpy.fft.fftfreq(data.shape[dim], 1.0/fSample)
        # select only the positive frequencies
        if posFreq :
            posfreqIdx = [i for i in numpy.argsort(freqs) if freqs[i] >= 0]
            # build an index expression to get the subset of data we want
            idx = [ slice(0,ft.shape[i]) for i in range(len(ft.shape))]
            idx[dim] = [i for i in numpy.argsort(freqs) if freqs[i] >= 0]
            # grab the wanted subset
            ft  = ft[tuple(idx)]
            freqs=freqs[posfreqIdx]
    else:
        raise Exception("data should be a numpy array or list of numpy arrays.")
        
    return (ft,freqs)  



def ifft(data, dim=0):
    '''inverse Fourier transform for a list of datapoints.
    
    Transforms the data from the time domain to the frequency domain. Returns
    a power spectrum.
    
    Parameters
    ----------
    data : list of datapoints (numpy arrays) or a single numpy array.
    dim : the dimension over which the fourier filter needs to be applied  (0)
    
    Returns
    -------
    out : (ft,freqs) the fourier transform of the data and the frequency bins
    
    '''        
    if not isinstance(dim, int):
        raise Exception("dim is not a int.")   

    if not isinstance(data,numpy.ndarray):
        ft = clonelist(data)
        for k in range(0,len(data)):            
            ft[k] = numpy.fft.ifft(ft[k], axis=dim)
        return 
    elif isinstance(data,numpy.ndarray):
        ft = numpy.fft.ifft(data, axis=dim)
    else:
        raise Exception("data should be a numpy array or list of numpy arrays.")
        
    return ft


def powerspectrum(data, dim, fSample=1):
    '''return the power spectral density of the data
    
    Assuming that the fourierfilter has been applied to the data, this function
    returns the frequency of the spectrum of each datapoint.
    
    Parameters
    ----------
    data : list of datapoints (numpy arrays) or a single numpy array.
    fSample : the sampling frequency of the data.
    
    Returns
    -------
    out : (psd,freqs) the power-spectral-density of the data and the list of frequency bins
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> hdr = ftc.getHeader()
    >>> freqs = preproc.powerspectrum(data, dim=1, hdr.fSample)
    >>> data = bufhelp.gatherdata("start",10,"stop")
    >>> data = preproc.powerspectrum(data, dim=1, bufhelp.fSample)
    '''

    ft,freqs = fouriertransform(data,dim,fSample,posFreq=True)
    ft = numpy.abs(ft) # convert to amplitude
    
    return (ft,freqs)

def fftfilter(data, dim, band, fSample=1):
    '''Applies a bandpass filter to the data.
    
    The band argument defines the range of the bandpass filter, it can either
    be a tuple, list or a function. If it is a tuple or a list it should 
    contain either 2 or 4 elements:
    
    2 elements - All frequencies < band[0] and > band[1] will be multiplied by
                 0.
    4 elements - All frequencies < band[0] and > band[3] will be mutliplied by 
                 0. All frequencies between band[0] and band[1] will be 
                 multiplied by (frequency - band[0])/(band[1]-band[0]). All 
                 frequencies between band[2] and band[3] will be multiplied by 
                 (band[3] - frequency)/(band[3]-band[2]). 
    
    If the band argument is a function then each frequency will be multiplied
    by band(frequency).
  
    Parameters
    ----------
    data : list of datapoints (numpy arrays) or a single numpy array.
    band : the band for the filter, should be a tuple or list containing either
    2 or 4 elements, or a function that maps numbers on numbers.
    fsample : the sampling frequency of the data
    dim : the dimension over which the spectral filter has been applied
    
    Returns
    -------
    out : a clone of data on wich a spectral bandpass filter has been applied.
    '''
    data,freqs = fouriertransform(data, dim, fSample, posFreq=False)
    wght = mkFilter(numpy.abs(freqs),band)
    # make the shape of wght match that of data so can apply the weighting easily
    wght = wght.reshape([1 if d!=dim else wght.size for d in range(data.ndim)])
    data = data * wght
    # inverse fourier transform to get back to time-domain
    data = numpy.real(ifft(data,dim))
    return data

def selectbands(data,band,dim=0,threshold=0,bins=None):
    """ select a subset of features given by band along the specified dim"""
    # compute the weighting over bin elements
    if bins is None:
        wght = mkFilter(data.shape[dim],band)
    else:
        if len(bins) != data.shape[dim] :
            raise("dimension bins is inconsistent with it's size!!");
        wght = mkFilter(bins,band)
    # threshold to identify which bins to keep
    keep = wght>threshold
    # build index expression to select the kept bits
    idx = [ slice(0,data.shape[i]) for i in range(data.ndim)];
    idx[dim] = keep
    data = data[tuple(idx)]
    return (data,keep)


def mkFilter(bins,band,xscale=None):
    """ make a weighting over entries as specified by band"""
    # convert from number of bins to actual bin values
    if isinstance(bins,int) :
        bins = numpy.arange(0,bins)
        if not xscale is None : # apply the scaling
            bins = bins*xscale
    # use bandfunc to get the weighting for each bin given it's value
    wght = numpy.array([ _bandfunc(n,band) for n in bins])
    return wght
    
def _bandfunc(x, band):
    """function get get a weighting for each index for a trapziod specified by 4 band numbers"""
    if len(band) == 2:
        if x < band[0] or x > band[1]:
            return 0
        else:
            return 1
    elif len(band) == 4:
        if x < band[0] or x > band[3]:
            return 0
        elif x < band[1]:
            return (x - band[0])/(band[1]-band[0])
        elif x > band[2]:
            return (band[3] - x)/(band[3]-band[2])
        else:
            return 1
    else:
        return band(x)
             
def selecttimeband(data, timeband, milliseconds=False, fSample=1):
    '''Applies a timeband filter to the data.
    
    Removes any samples that do not fall within the range defined by the 
    timeband. If milliseconds is true the timeband is interpreted in
    milliseconds.
    
    Parameters
    ----------
    data : list of datapoints (numpy arrays) or a single numpy array.
    timeband : tuple or list containing the lower bounds (first element) and
    upper bound (second element) of the timeband.
    milliseconds : boolean indicating if timeband is expressed in milliseconds.
    fSample : the sampling frequency of the data, only required if the timeband
    is expressed in milliseconds.
    
    Returns
    -------
    out : a clone of data on wich a timeband filter has been applied.
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> hdr = ftc.getHeader()
    >>> data = preproc.timebandfilter(data, (250,350), hdr.fSample)
    >>> data = bufhelp.gatherdata("start",10,"stop")
    >>> data = preproc.powerspectrum(data, (25,35))
    '''
    
    binsize=1000.0/fSample if milliseconds else 1/fSample
    filt = mkFilter(data.shape[1],timeband,binsize)
    return selectbands(data,1,filt)

def removeoutliers(data,dim=0,alreadybad=None,threshold= (None,3.1)):
    '''Removes outliers from data
    
    Removes bad trails from the data. Applies outlier detection on the rows
    of the data, after having flattened the datapoint.
    
    Parameters
    ----------
    data : list of datapoints (numpy arrays) or a single numpy array.
    threshold : the upper and lower bound of the thershold in a tuple expressed
    in standard deviations.  
    Outputs:
    --------
    data : the data with the outliers removes
    inliers : the indices of the good elements along dim
    '''
    
    if not isinstance(data,numpy.ndarray):
        X = numpy.array([d.flatten() for d in data])
    else:
        X = data
        
    inliers, outliers = outlierdetection(X, dim, threshold)    
    # build an index expression to get the subset of data we want
    idx = [ slice(0,X.shape[i]) for i in range(X.ndim)]
    idx[dim] = inliers
    X = X[tuple(idx)]
        
    if not isinstance(data,numpy.ndarray):
        dataout = rebuilddata(X,data)            
        return (dataout, inliers)
    elif isinstance(data,numpy.ndarray):
        return (X,inliers)
    else:
        raise Exception("data should be a numpy array or list of numpy arrays.")


def badchannelremoval(data, badchannels = None, threshold = (-numpy.inf,3.1)):
    '''Removes bad channels from the data.
    
    Removes bad channels from the data. Basically applies outlier detection
    on the columns in the data and removes them if necessary.
    
    If badchannels are provided these will simply be removed from the data.
    
    Parameters
    ----------
    data : list of datapoints (numpy arrays) or a single numpy array.
    badchannels : list of indices of bad channels
    threshold : the upper and lower bound of the thershold in a tuple expressed
    in standard deviations.  
    
    Returns
    -------
    out : a tuple of a clone of data from which bad channels have been removed 
    and a list of the indices of the outliers.
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> data, badch = preproc.badchannelremoval(data)
    >>> data = bufhelp.gatherdata("start",10,"stop")
    >>> data, badch = preproc.badchannelremoval(data)
    '''
    return removeoutliers(data,0,threshold=threshold,alreadybad=badchannels)

    
def badtrialremoval(data, events = None, threshold = (None,3.1)):
    '''Removes bad trails from the data.
    
    Removes bad trails from the data. Applies outlier detection on the rows
    of the data, after having flattened the datapoint.
    
    Parameters
    ----------
    data : list of datapoints (numpy arrays) or a single numpy array.
    threshold : the upper and lower bound of the thershold in a tuple expressed
    in standard deviations.  
    
    Returns
    -------
    out : a tuple of a clone of data from which bad trails have been removed 
    and a list of the indices of the outliers.
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> data, badtrl = preproc.badchannelremoval(data)
    >>> data = bufhelp.gatherdata("start",10,"stop")
    >>> data, badtrl = preproc.badchannelremoval(data)
    '''

    return removeoutliers(data,dim=-1,threshold=threshold)
    
    
def outlierdetection(X, dim=0, threshold=(None,3), alreadybad=None, maxIter=3, feat="var"):
    '''Removes outliers from X. Based on idOutliers.m
    
    Removes outliers from X based on robust coviarance variance/mean 
    computation.
    
    Parameters
    ----------
    data : list of datapoints (numpy arrays) or a single numpy array.
    dim : the dimension along with outliers need to be detected.
    threshold : the upper and lower bound of the thershold in a tuple expressed
    in standard deviations.  
    maxIter : number of iterations that need to be performed.
    feat : feature on which outliers need to be based. "var" for variance, "mu"
    , for mean or a numpy array of the same shape as X.
    
    Returns
    -------
    out : a tuple of a list of inlier indices and a list of outlier indices.
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> inliers, outliers = preproc.outlierdetection(data)
    '''   

    # convert from dim to get outlier indices over, to dim to compute features over
    if dim<0: dim=X.ndim+dim
    featdim = tuple([ x for x in range(len(X.shape)) if x!=dim])
    
    if feat=="var":
        feat = numpy.sqrt(numpy.abs(numpy.var(X,axis=featdim)))
    elif feat =="mu":
        feat = numpy.mean(X,axis=featdim)
    elif isinstance(feat,numpy.array):
        if not (all([isinstance(x,(int , float)) for x in feat]) and feat.shape == X.shape):
            raise Exception("Unrecognised feature type.")
    else:
        raise Exception("Unrecognised feature type.")

    inliers = numpy.ones(feat.shape, dtype=numpy.bool)
    if alreadybad is not None: # mark already known as bad
        inliers[alreadybad]=False
    for i in range(0,maxIter):
        mufeat = numpy.median(feat[inliers])
        stdfeat = numpy.std(feat[inliers])
        bad = numpy.zeros_like(inliers)
        if threshold[1] is not None:
            high = mufeat+threshold[1]*stdfeat
            bad = bad | (feat > high)
        if threshold[0] is not None:
            low = mufeat+threshold[0]*stdfeat
            bad = bad | (feat < low)

        if not bad.any():
            break
        else:
            inliers = inliers & ~bad

    return (list(numpy.where(inliers)[0]), list(numpy.where(~inliers)[0]))



def concatdata(data,dim=0):
    '''Concatenates a list of datapoints into a single numpy array.
    
    Parameters
    ----------
    data : list of datapoints (numpy arrays), assumed [nSamples x nChannels]
    dim  : dimension along which to concatenate
    
    Returns
    -------
    out : a numpy array containing the datapoints in data. [nSamples x nChannels x nTrials]
    
    Examples
    --------
    >>> data = bufhelp.gatherdata("start",10,"stop")
    >>> X = preproc.concatdata(data)
    
    See Also
    --------
    rebuild
    '''
    
    if not isinstance(data, list):
        raise Exception("Data is not a list.")
        
    if not all([isinstance(x,numpy.ndarray) for x in data]):
        raise Exception("Data contains non numpy.array elements.")
    
    if not all([x.shape[1] == data[0].shape[1] for x in data]):
        raise Exception("Inconsistent number of channels in data!")
    
    if dim<2:
        cdata = numpy.concatenate(data,axis=dim)
    elif dim==2: # make new dim
        cdata = numpy.concatenate([x[:,:,numpy.newaxis] for x in data],axis=dim)

    return cdata

def rebuilddata(X,data):
    '''Rebuilds a list of datapoints based on a large numpy array.
    
    Basically reverses concatdata.
    
    Parameters
    ----------
    X : a single numpy array, with a number of rows equal to the total number 
    of samples in data.
    data : list of datapoints (numpy arrays).
    
    Returns
    -------
    out : a clone of data that contains samples from X.
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> X = preproc.concatdata(data)
    >>> X = X + 1
    >>> data = preproc.rebuilddata(X,data)
    '''   
    
    if X.shape[0] != sum([x.shape[0] for x in data]):
        raise Exception("Different number of samples in X and data!")
    
    data = clonelist(data)    
    
    start = 0;
    for i in range(0,len(data)):
        end = start + data[i].shape[0]
        data[i] = X[start:end,:]
        start = start + data[i].shape[0]
        
    return data

def clonelist(original):
    '''Clones a list.
    
    Creates a new list and adds all the object of to original list to it. If
    the objects in the original list have a copy or deepcopy method it will be
    used.
    
    Parameters
    ----------
    original : the list that eneds to be cloned
    
    Returns
    -------
    out : a clone of the list and its content
    
    Examples
    --------
    >>> a = [1,2,3,4]
    >>> b = clonelist(a)
    >>> events = ftc.getEvents(0,100)
    >>> events_copy = clonelist(events)
    '''
    
    clone = []

    for element in original:
        if hasattr(element,"deepcopy"):
            clone.append(element.deepcopy())
        elif hasattr(element,"copy"):
            clone.append(element.copy())
        else:
            clone.append(element)
    
    return clone


if __name__=="main":
    #%pdb
    import preproc
    import numpy
    fs   = 40
    data = numpy.random.randn(3,fs,5)  # 1s of data    
    ppdata=preproc.detrend(data,0)
    ppdata=preproc.spatialfilter(data,'car')
    ppdata=preproc.spatialfilter(data,'whiten')
    ppdata,goodch=preproc.badchannelremoval(data)
    ppdata,goodtr=preproc.badtrialremoval(data)
    goodtr,badtr=preproc.outlierdetection(data,-1)
    Fdata,freqs=preproc.fouriertransform(data, 2, fSamples=1, posFreq=True)
    Fdata,freqs=preproc.powerspectrum(data, 1, dim=2)
    filt=preproc.mkFilter(10,[0,4,6,7],1)
    filt=preproc.mkFilter(numpy.abs(numpy.arange(-10,10,1)),[0,4,6,7])
    ppdata=preproc.fftfilter(data,1,[0,3,4,6],fs)
    ppdata,keep=preproc.selectbands(data,[4,5,10,15],1); ppdata.shape
