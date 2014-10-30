import scipy.signal 
import numpy
from math import ceil

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

def spatialfilter(data, type="car",whitencutoff=1e-15):
    '''Spatial filter for a list of datapoints.
    
    Applies a spatial filter to the data offers two types:
    
    car    - the common average reference
    whiten - Whitening transform
    
    Both are based on eegtools, see references.
    
    Parameters
    ----------
    data : list of datapoints (numpy arrays) or a single numpy array.
    type : a string that indicates the type of spatial filter should either 
    be "car" or "whitten"
    whittencutoff : Only used with the whitten transform, it specifies the 
    cut-off value as the fraction of the largest eigenvalue of D.
    
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
        
        X = numpy.dot(numpy.eye(X.shape[0])-(1.0/X.shape[0]),X)
        
    elif type=="whiten":
        
        if not isinstance(whitencutoff, (int,float,long)):
            raise Exception("whitencutoff is not a number.") 
            
        C = numpy.cov(X)
        e, E = numpy.linalg.eigh(C)
        X = numpy.dot(reduce(numpy.dot,[E, numpy.diag(numpy.where(e > numpy.max(e) * whitencutoff, e, numpy.inf)**-.5), E.T]),X)
    
    if not isinstance(data,numpy.ndarray):
        return rebuilddata(X,data)
    else:
        return X
    
def fouriertransform(data, fSample, dim=0):
    '''Fourier transform for a list of datapoints.
    
    Transforms the data from the time domain to the frequency domain. Returns
    a power spectrum.
    
    Parameters
    ----------
    data : list of datapoints (numpy arrays) or a single numpy array.
    fSample ; the sampling frequency of the data
    dim : the dimension over which the fourier filter needs to be applied
    
    Returns
    -------
    out : a clone of data on wich a fourier transform has been applied
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> hdr = ftc.getHeader()
    >>> data = preproc.fouriertransform(data, hdr.fSample)
    >>> data = bufhelp.gatherdata("start",10,"stop")
    >>> data = preproc.fouriertransform(data, bufhelp.fSample)
    '''
        
    if not isinstance(dim, int):
        raise Exception("dim is not a int.")   
        
    if not isinstance(fSample, float):
        raise Exception("fSample is not a float")
    
    if not isinstance(data,numpy.ndarray):
        dataclone = clonelist(data)
        
        for k in range(0,len(data)):
            data = dataclone[k]
            ft = numpy.abs(numpy.fft.fft(data, axis=dim))**2
            freqs = numpy.fft.fftfreq(data.shape[0], 1.0/fSample)
            idx = [i for i in numpy.argsort(freqs) if freqs[i] >= 0]
    
            index = list(data.shape)
            index[dim] = len(idx)
            ps = numpy.zeros(index)
            
            
            s = list(data.shape)
            del s[dim]
            s = s[0]
            for i in range(0,s):
                ind = [i,i]
                ind[dim] = list(range(0,len(idx)))
                sel = [i,i]
                sel[dim] = idx
                ps[ind] = ft[sel]
                
            dataclone[k] = ps
            
        return dataclone
    elif isinstance(data,numpy.ndarray):
        ft = numpy.abs(numpy.fft.fft(data, axis=dim))**2
        freqs = numpy.fft.fftfreq(data.shape[0], 1.0/fSample)
        idx = [i for i in numpy.argsort(freqs) if freqs[i] >= 0]

        index = list(data.shape)
        index[dim] = len(idx)
        ps = numpy.zeros(index)
        
        
        s = list(data.shape)
        del s[dim]
        s = s[0]
        for i in range(0,s):
            ind = [i,i]
            ind[dim] = list(range(0,len(idx)))
            sel = [i,i]
            sel[dim] = idx
            ps[ind] = ft[sel]
    else:
        raise Exception("data should be a numpy array or list of numpy arrays.")
        
        return ps   
        
def spectrum(data, fSample, dim=0):
    '''Returns a list of frequenceis that form the spectrum of the data.
    
    Assuming that the fourierfilter has been applied to the data, this function
    returns the frequency of the spectrum of each datapoint.
    
    Parameters
    ----------
    data : list of datapoints (numpy arrays) or a single numpy array.
    fSample : the sampling frequency of the data.
    
    Returns
    -------
    out : a list of frequencies
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> hdr = ftc.getHeader()
    >>> freqs = preproc.spectrum(data, hdr.fSample)
    >>> data = bufhelp.gatherdata("start",10,"stop")
    >>> data = preproc.spectrum(data, bufhelp.fSample)
    '''
    
    if not isinstance(data,numpy.ndarray):
        freqs = numpy.fft.fftfreq(data[0].shape[dim]*2, 1.0/fSample)    
    elif isinstance(data,numpy.ndarray):
        freqs = numpy.fft.fftfreq(data.shape[dim], 1.0/fSample)    
    else:
        raise Exception("data should be a numpy array or list of numpy arrays.")        
        
    return [freqs[i] for i in numpy.argsort(freqs) if freqs[i] >= 0]

def spectralfilter(data, band, fSample, dim=0):
    '''Applies a fourier transform and bandpass filter to the data.
    
    Applies a bandpass filter to the data.
    
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
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> data = preproc.fouriertransform(data)
    >>> hdr = ftc.getHeader()
    >>> data = preproc.spectralfilteronly(data, (10,12), hdr.fSample)
    >>> data = bufhelp.gatherdata("start",10,"stop")
    >>> data = preproc.fouriertransform(data)
    >>> data = preproc.spectralfilteronly(data, (8, 10, 12, 14), bufhelp.fSample)
    '''
    data = fouriertransform(data, fSample, dim)
    
    return spectralfilteronly(data,band,fSample,dim)
    
        
def spectralfilteronly(data, band, fSample, dim=1):
    '''Applies a bandpass filter to the data.
    
    Applies a bandpass filter to the data, assumes it has already been 
    transformed to the frequency-power domain. 
    
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
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> data = preproc.fouriertransform(data)
    >>> hdr = ftc.getHeader()
    >>> data = preproc.spectralfilteronly(data, (10,12), hdr.fSample)
    >>> data = bufhelp.gatherdata("start",10,"stop")
    >>> data = preproc.fouriertransform(data)
    >>> data = preproc.spectralfilteronly(data, (8, 10, 12, 14), bufhelp.fSample)
    '''
    
    if isinstance(band, (tuple,list)):
        if not (len(band)==2 or len(band)==4):
            raise Exception("band is wrong length tuple/list")
    elif callable(band):
        try:
            if not isinstance(band(4.0), (int,float,long)):
                raise Exception("band does not return a number")
        except:
            raise Exception("band does not have accept floats as an argument")
    else:
        raise Exception("band must either be a callable, a tuple or a list")
        
    if not isinstance(fSample,float):
        raise Exception("fSample is not a float.")
        
    if not isinstance(dim,int):
        raise Exception("dim is not an int.")
               
    if not isinstance(data,numpy.ndarray):
        for X in data:
            freqs = spectrum(data,fSample)
            s = list(X.shape)
            del s[dim]
            for j in range(0,s[0]):
                index = [j,j]
                for i in range(0,X.shape[dim]):
                    index[dim] = i
                    X[index] = X[index] * _bandfunc(freqs[i], band)           
    elif isinstance(data,numpy.ndarray):
        freqs = spectrum(data,fSample, dim)
        s = list(data.shape)
        del s[dim]
        for j in range(0,s[0]):
            index = [j,j]
            for i in range(0,data.shape[dim]):
                index[dim] = i
                data[index] = data[index] * _bandfunc(freqs[i], band)
    else:
        raise Exception("data should be a numpy array or list of numpy arrays.")
        
    return data    
        
def _bandfunc(x, band):
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
        
     
def timebandfiler(data, timeband, milliseconds=False, fSample=None):
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
    >>> data = preproc.timebandfiler(data, (250,350), hdr.fSample)
    >>> data = bufhelp.gatherdata("start",10,"stop")
    >>> data = preproc.spectrum(data, (25,35))
    '''
    
    if not isinstance(timeband, (list,tuple)):
        raise Exception("Timeband not a tuple or list.")
    
    if len(timeband) != 2:
        raise Exception("Timeband is not size 2.")
        
    if not all(map(lambda x: isinstance(x,(int,long,float)), timeband)):
        raise Exception("timeband contains non-number elements.")
        
    if timeband[0] > timeband[1]:
        raise Exception("Lower bound higher than upper bound.")
        
    if not isinstance(data, list):
        raise Exception("Data is not a list.")
        
    if not all(map(lambda x: isinstance(x,numpy.ndarray), data)):
        raise Exception("Data contains non numpy.array elements.")

    if not isinstance(milliseconds,bool):
        raise Exception("milliseconds is not a boolean")
        
    data = clonelist(data)        
    
    if milliseconds:
        if not isinstance(fSample, float):
            raise Exception("fSample is not a float.")
            
        lower = (timeband[0]/1000.0)*float(fSample)
        upper = (timeband[1]/1000.0)*float(fSample)
    else:
        lower = timeband[0]
        upper = timeband[1]
    
    lower = int(lower)
    upper = int(ceil(upper))    
    
    for i in range(0,len(data)):
        data[0] = data[0][lower:upper,:]
        
    return data
     


def concatdata(data):
    '''Concatenates a list of datapoints into a single numpy array.
    
    Parameters
    ----------
    data : list of datapoints (numpy arrays).
    
    Returns
    -------
    out : a numpy array containing the datapoints in data.
    
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
        
    if not all(map(lambda x: isinstance(x,numpy.ndarray), data)):
        raise Exception("Data contains non numpy.array elements.")
    
    if not all(map(lambda x: x.shape[1] == data[0].shape[1], data)):
        raise Exception("Inconsistent number of channels in data!")
        
    return numpy.concatenate(data)
    
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
    
    if not isinstance(data, list):
        raise Exception("Data is not a list.")
        
    if not all(map(lambda x: isinstance(x,numpy.ndarray), data)):
        raise Exception("Data contains non numpy.array elements.")
    
    if not all(map(lambda x: x.shape[1] == data[0].shape[1], data)):
        raise Exception("Inconsistent number of channels in data!")
    
    if badchannels is not None:
        goodchannels = [x for x in range(data[0].shape[1]) if x not in badchannels]        
        
        if not isinstance(data,numpy.ndarray):
            data = clonelist(data)
            for i in range(0,len(data)):
                data[i] = data[i][:,goodchannels]            
        else:
            return data[:,badchannels]
    
    if not isinstance(data,numpy.ndarray):
        X = concatdata(data)
    elif isinstance(data,numpy.ndarray):
        X = data
    else:
        raise Exception("data should be a list of numpy arrays or a numpy array")
    
    inliers, outliers = outlierdetection(X, 0, threshold)    
        
    if not isinstance(data,numpy.ndarray):
        return (rebuilddata(X[:,inliers],data), outliers)
    elif isinstance(data,numpy.ndarray):
        return (X[:,inliers], outliers)
    else:
        raise Exception("data should be a numpy array or list of numpy arrays.")

def badtrailremoval(data, events = None, threshold = (None,3.1)):
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
    
    if not isinstance(data,numpy.ndarray):
        X = numpy.array([d.flatten() for d in data])
    else:
        X = data
        
    inliers, outliers = outlierdetection(X, 1, threshold)    
        
    if not isinstance(data,numpy.ndarray):
        dataout = []
        
        for i in inliers:
            dataout.append(data[i].copy())
            
        if events is not None:
            eventsout = []
            
            for i in inliers:
                if hasattr(events[i],"deepcopy"):
                    eventsout.append(events[i].deepcopy())
                elif hasattr(events[i],"copy"):
                    eventsout.append(events[i].copy())
                else:
                    eventsout.append(events[i])
        
            return (dataout, eventsout, outliers)            
            
        return (dataout, outliers)
    elif isinstance(data,numpy.ndarray):
        return (X[inliers,:], outliers)
    else:
        raise Exception("data should be a numpy array or list of numpy arrays.")
    
def outlierdetection(X, dim=0, threshold=(None,3), maxIter=3, feat="var"):
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
  
    if feat=="var":
        feat = numpy.sqrt(numpy.abs(numpy.var(X,dim)))
    elif feat =="mu":
        feat = numpy.mean(X,dim)
    elif isinstance(feat,numpy.array):
        if not (all(map(lambda x: isinstance(x,(int , long , float)), feat)) and feat.shape == X.shape):
            raise Exception("Unrecognised feature type.")
    else:        
        raise Exception("Unrecognised feature type.")
    
    outliers = []
    inliers = numpy.array(range(0,max(feat.shape)))    

    mufeat = numpy.zeros(maxIter)
    stdfeat = numpy.zeros(maxIter)
    for i in range(0,maxIter):
        mufeat = numpy.median(feat[inliers])
        stdfeat = numpy.std(feat[inliers])

        if threshold[0] is None:
            high = mufeat+threshold[1]*stdfeat
            bad = (feat > high)
        elif threshold[1] is None:
            low = mufeat+threshold[0]*stdfeat
            bad = (feat < low)
        else:
            high = mufeat+threshold[1]*stdfeat
            low = mufeat+threshold[0]*stdfeat
            bad = (feat > high) * (feat < low)

        if not any(bad):
            break
        else:
            outliers = outliers + list(inliers[bad])
            inliers = inliers[[ not x for x in bad]]
    
    return (list(inliers), outliers)
    

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
    
    if X.shape[0] != sum(map(lambda x: x.shape[0], data)):
        raise Exception("Different number of samples in X and data!")
    
    data = clonelist(data)    
    
    start = 0;
    for i in range(0,len(data)):
        end = start + data[i].shape[0]
        data[i] = X[start:end,:]
        start = start + data[i].shape[0]
        
    return data
