import numpy
import scipy.stats
import sklearn.grid_search
import sklearn.cross_validation

def fit(data, events, classifier, mapping=dict(), params = None, folds = 5, shuffle=True, reducer=None):
    '''Calls the fit function on the classifier using data and events.
    
    The mapping argument is passed on to the createclasses function.
    
    If events or data is a numpy array it will passed along unchanged to the 
    classifiers fit function. (Indeed if data and events are both numpy arrays
    there is little point in using this function.)
    
    If a params dict (or list of dicts ) is provided an exhoustive, kfold cross 
    validated, grid search will be performed to find the best parameter 
    combination.

    If a reducer is provided the samples within a datapoint will be reduced to
    a single sample using any of the following methods:
    
    concat   - concatenates all the samples together horizontally
    mean     - takes the average of all samples    
    max      - takes the maximum of all samples
    min      - takes the minimum of all samples
    median   - takes the median of all samples
    mode     - takes the mode of all samples
    function - uses this function to reduce the samples. Function should map a 
    numpy array onto a float, int or long.
    
    If no reducer has been provided all samples will be treated as a unique
    datapoint when fitting the classifier.
    
    Parameters
    ----------
    data : a list of datapoints (numpy arrays) or a numpy array
    events : a list of fieldtrip events or a numpy array
    classifier ; a sklearn classifier
    mapping : a dict that describes how the events are mapped on the classes
    params : a dict of parameters over which a grid search will be performed
    folds : the number of folds to use for kfold cross validation during grid 
    search
    shuffle : whether the data should be shuffled
    reducer : the method used to reduce multiple samples to one sample. Should
    either be a string with the name of the reducer or a callable object.
        
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> classifier = sklearn.svm.LinearSVC()
    >>> mapping = dict()
    >>> skwrap.fit(data, events, classifier, mapping, True)
    '''

    if not isinstance(shuffle, bool):
        raise Exception("shuffle should be a bool")
    
    if not (hasattr(classifier,"fit") and hasattr(classifier,"predict")):
        raise Exception("classifier should be a sklearn classifier.")
    
    X = createdata(data, reducer)

    if shuffle:
        numpy.random.shuffle(X)

    if events is not None:
        if not isinstance(data,numpy.ndarray):
            if reducer is not None:
                Y = createclasses(events, 1, mapping)
            else:
                Y = createclasses(events, data[0].shape[0], mapping)
        else:
            Y = events
    else:
        Y = None
    
    if params is not None:
        if isinstance(params,dict):
            if any(map(lambda x: not isinstance(x,str), params.keys())):
                raise Exception("param keys should be strings")
            if any(map(lambda x: not isinstance(x,list), params.values())):
                raise Exception("param values should be lists")
        elif isinstance(params,list):
            if any(map(lambda y: any(map(lambda x: not isinstance(x,str), y.keys())),params)):
                raise Exception("all dicts in param keys should be strings")
            if any(map(lambda y: any(map(lambda x: not isinstance(x,list), y.values())),params)):
                raise Exception("all dicts in param values should be lists")
        else:
            raise Exception("param should be a dict or list of dicts")
            
        if not isinstance(folds, int):
            raise Exception("folds should be an integer")
        
        folds = sklearn.cross_validation.KFold(X.shape[0], folds, shuffle=shuffle)
        grid = sklearn.grid_search.GridSearchCV(classifier, params, cv=folds)
        
        if Y is None:
            grid.fit(X)
        else:
            grid.fit(X,Y)
        
        classifier.set_params(**grid.best_params_)
        
    if Y is None:
        classifier.fit(X)
    else:               
        classifier.fit(X,Y)
        
def predict(data, classifier, mapping = None, reducerdata=None, reducerpred=None):
    '''Returns a prediction for each datapoint in data.
    
    If a mapping has been provided the this function will construct a list of 
    whatever values are in this mapping by using the predictions class numbers
    as keys.
    
    If necessary either the data or the predictions can be reduced, if this is 
    not done multiple predictions per datapoint can occur (in which case the 
    entire array of nSamples * len(data) predictions will be returned).
    
    The reducer describes how these multiple predictions/samples should be 
    reduced to a single probability/sample. These will be applied to all 
    predictions/samples for a single class/channel for each datapoint. The 
    following reducers are supported:

    concat   - concatenates all the samples together horizontally (reducedata 
    only)
    mean     - takes the average of all probabilities/samples 
    max      - takes the maximum of all probabilities/samples
    min      - takes the minimum of all probabilities/samples
    median   - takes the median of all probabilities/samples
    mode     - takes the mode of all probabilities/samples
    function - uses this function to reduce the probabilities/samples. Function 
    should map a numpy array onto a float, int or long.
    
    The reducer is applied to the class numbers, before any mapping is applied.
    Using the mean,max,min or median reducers probably doesn't make much sense.
    If the mean reducer is used mapping won't be applied.
    
    Parameters
    ----------
    data : a list of datapoints (numpy arrays) or a numpy array
    classifier ; a sklearn classifier
    mapping : a mapping containing all class numbers as keys
    reducerdata : the method used to reduce multiple samples to one sample. Should
    either be a string with the name of the reducer or a callable object.
    reducerpred : the method used to reduce multiple predictions in case flatten
    is not true. Should either be a string with the name of the reducer or a 
    callable object.
    
    Returns
    -------
    out : a numpy array of class numbers. Or a list of values of the mapping
    that are associated with each predictions class number.
        
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> classifier = sklearn.svm.LinearSVC()
    >>> mapping = dict()
    >>> skwrap.fit(data, events, classifier, mapping, True)
    >>> data, events = ftc.getData(100,150)
    >>> pred = skwrap.predict(data, classifier, None, True)
    '''    
    
    if not (hasattr(classifier,"fit") and hasattr(classifier,"predict")):
        raise Exception("classifier should be a sklearn classifier.")

    if isinstance(data,numpy.ndarray):
        if reducerpred is not None and reducerdata is not None:
            raise Exception("unable to reduce both data and predictions")

    X = createdata(data,reducerdata)
    pred = classifier.predict(X)

    if reducerpred is not None:
        if reducerpred == "mean":
            pred = reduceArray(pred,data,numpy.mean)
            return pred
        elif reducerpred == "max":
            pred = reduceArray(pred,data,max)            
        elif reducerpred == "min":
            pred = reduceArray(pred,data,min)            
        elif reducerpred == "median":
            pred = reduceArray(pred,data,numpy.median)            
        elif reducerpred == "mode":
            pred = reduceArray(pred,data,lambda x: scipy.stats.mode(x)[0][0])
        elif callable(reducerpred):
            pred = reduceArray(pred,data,reducerpred)
        else:
            raise Exception("Unkown reducer.")
    
    if mapping is None:
        return pred        
    elif isinstance(mapping,dict):
        if not all(map(lambda x: isinstance(x,numpy.ndarray), data)):
            raise Exception("data contains non numpy.array elements.")
        
        if not all(map(lambda x: x.shape[1] == data[0].shape[1], data)):
            raise Exception("Inconsistent number of channels in data!")

        if not all(map(lambda x: x.shape[0] == data[0].shape[0], data)):
            raise Exception("Inconsistent number of samples in data!") 
                            
        return [mapping[int(p)] for p in pred ]
    
def predict_proba(data, classifier, reducerdata=None, reducerpred=None):
    '''Returns the probability of each class for each datapaoint.
    
    Creates a numpy array with a column for each class and a row for each 
    datapoint. The order of the classes is based on the number associated with
    the class, ordered from low to high.
    
    If necessary either the data or the predictions can be reduced, if this is 
    not done multiple predictions per datapoint can occur (in which case the 
    entire array of nSamples * len(data) predictions will be returned).
    
    The reducer describes how these multiple predictions/samples should be 
    reduced to a single probability/sample. These will be applied to all 
    predictions/samples for a single class/channel for each datapoint. The 
    following reducers are supported:

    concat   - concatenates all the samples together horizontally (reducedata 
    only)
    mean     - takes the average of all probabilities/samples 
    max      - takes the maximum of all probabilities/samples
    min      - takes the minimum of all probabilities/samples
    median   - takes the median of all probabilities/samples
    mode     - takes the mode of all probabilities/samples
    function - uses this function to reduce the probabilities/samples. Function 
    should map a numpy array onto a float, int or long.
    
    Parameters
    ----------
    data : a list of datapoints (numpy arrays) or a numpy array
    classifier ; a sklearn classifier
    flatten : a boolean indicating if samples within a datapoint should be 
    concatenated together
    reducer : the method used to reduce multiple predictions in case flatten
    is not true. Should either be a string with the name of the reducer or a 
    callable object.
    
    Returns
    -------
    out : a numpy array of containing probabilities for each class for each 
    datapoint
        
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> classifier = sklearn.svm.LinearSVC()
    >>> skwrap.fit(data, events, classifier, mapping, True)
    >>> data, events = ftc.getData(100,150)
    >>> prob = skwrap.predict_proba(data, classifier, None, True)
    ''' 
    
    if not (hasattr(classifier,"fit") and hasattr(classifier,"predict_proba")):
        raise Exception("classifier should be a sklearn classifier with the predict_proba method.")

    if isinstance(data,numpy.ndarray):
        if reducerpred is not None and reducerdata is not None:
            raise Exception("unable to reduce both data and predictions")
    
    X = createdata(data,reducerdata)
    pred = classifier.predict_proba(X)

    if reducerpred is None:
        return pred
    else:
        if reducerpred == "mean":
            pred = reduceArray(pred,data,numpy.mean)
        elif reducerpred == "max":
            pred = reduceArray(pred,data,max)            
        elif reducerpred == "min":
            pred = reduceArray(pred,data,min)            
        elif reducerpred == "median":
            pred = reduceArray(pred,data,numpy.median)            
        elif reducerpred == "mode":
            pred = reduceArray(pred,data,lambda x: scipy.stats.mode(x)[0][0])
        elif callable(reducerpred):
            pred = reduceArray(pred,data,reducerpred)
        else:
            raise Exception("Unkown reducer.")
        return pred
               
def createdata(data, reducer=None):
    '''Returns a numpy array containing the data in data.
    
    Concatenates all the samples in all the datapoints together.
    
    If a reducer is provided the samples within a datapoint will be reduced to
    a single sample using any of the following methods:
    
    concat   - concatenates all the samples together horizontally
    mean     - takes the average of all samples    
    max      - takes the maximum of all samples
    min      - takes the minimum of all samples
    median   - takes the median of all samples
    mode     - takes the mode of all samples
    function - uses this function to reduce the samples. Function should map a 
    numpy array onto a float, int or long.
    
    Parameters
    ----------
    data : a list of datapoints (numpy arrays) or a numpy array
    reducer : the method used to reduce multiple samples to one sample. Should
    either be a string with the name of the reducer or a callable object.
        
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> X = skwrap.createdata(data)
    '''    
    
    if not isinstance(data,numpy.ndarray):
        if not isinstance(data, list):
            raise Exception("data is not a list.")
            
        if not all(map(lambda x: isinstance(x,numpy.ndarray), data)):
            raise Exception("data contains non numpy.array elements.")
        
        if not all(map(lambda x: x.shape[1] == data[0].shape[1], data)):
            raise Exception("Inconsistent number of channels in data!")

        if not all(map(lambda x: x.shape[0] == data[0].shape[0], data)):
            raise Exception("Inconsistent number of samples in data!")
        
        if reducer is not None:
            if reducer == "concat":
                X = numpy.concatenate(map(lambda x: numpy.reshape(x, (1,x.size)), data))
            elif reducer == "mean":
                X = reduceArray(numpy.concatenate(data),data,numpy.mean)
            elif reducer == "max":
                X = reduceArray(numpy.concatenate(data),data,max)            
            elif reducer == "min":
                X = reduceArray(numpy.concatenate(data),data,min)            
            elif reducer == "median":
                X = reduceArray(numpy.concatenate(data),data,numpy.median)            
            elif reducer == "mode":
                X = reduceArray(numpy.concatenate(data),data,lambda x: scipy.stats.mode(x)[0][0])
            elif callable(reducer):
                X = reduceArray(numpy.concatenate(data),data,reducer)
            else:
                raise Exception("Unkown reducer.")       
        else:
            X = numpy.concatenate(data)
            
    elif isinstance(data,numpy.ndarray):
        X = data.copy()
    else:
        raise Exception("data should be a numpy array or list of numpy arrays.")
        
    return X
        
def createclasses(events, nSample = 1, mapping = dict()):
    '''Returns a numpy array of integers that describes the classes.
    
    The uniqueness of an event is based on the events type and value cast to a
    string.
    
    A mapping can be provided and it will be used to build the numpy array.
    This mapping should consist of a dict where the keys consist of a tuple 
    with the type and value cast to strings, and the values of the dict should
    consist of integers.
    
    If no mapping has been provided, or an empty dict is provided it will be 
    constructed based on the order of events in the list.
    
    If nSample has been provided each line in events will result in nSample
    lines in the returned numpy array.
    
    Parameters
    ----------
    events : a list of fieldtrip events
    nSample : the number of rows each events should have in the returning array
    mapping : a dict that describes how the events are mapped on the classes
    
    Returns
    -------
    out : a numpy array of classes or if no mapping has been provided
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> Y, map = skwrap.createclasses(events)
    >>> mapping = { ("a","2") : 0. ("a","3") : 1 , ("a","1") : 2 }
    >>> Y = skwrap.createclasses(events, 10, mapping)
    '''
    
    Y = numpy.zeros(len(events)*nSample)

    if not isinstance(mapping,dict):
        raise Exception("mapping should be a dict.")
        
    if len(mapping.items()) > 0:            
        
        if any(map(lambda x: not isinstance(x,tuple), mapping.keys())):
            raise Exception("keys in mapping contains non tuples")
        
        if any(map(lambda x: len(x) != 2, mapping.keys())):
            raise Exception("keys in mapping contains non lenght 2 tuples")
        
        if any(map(lambda x: not (isinstance(x[0],str) and isinstance(x[1],str)), mapping.keys())):
            raise Exception("tuples in keys contains non strings")
            
        if any(map(lambda x: not isinstance(x,int), mapping.values())):
            raise Exception("values in mapping contains non integers")
        
        j = 0
        for i in range(0,len(events)):
            key = (str(events[i].type) , str(events[i].value))
            if key in mapping:
                for k in range(0,nSample):
                    Y[j] = mapping[key]
                    j = j + 1
            else:
                raise Exception("event not found in mapping")
        return Y

    n = 0
    j = 0
    for i in range(0,len(events)):
        key = (str(events[i].type) , str(events[i].value))
        if key in mapping:
            for k in range(0,nSample):
                Y[j] = mapping[key]
                j = j + 1
        else:
            for k in range(0,nSample):
                Y[j] = n
                j = j + 1
            mapping[key] = n
            n = n + 1
            
    return Y
    
def reduceArray(pred, data, reducerfunc):
    '''Reduced the predictions.
    
    Parameters
    ----------
    pred : a numpy array containing the predictions
    data : list of datapoints (numpy arrays).
    reducerfunc : the function that will be used to reduce the probabilities.
    
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
    
    if pred.shape[0] != sum(map(lambda x: x.shape[0], data)):
        raise Exception("Different number of samples in pred and data!")
    
    out = numpy.zeros((len(data),pred.shape[1]))
    
    start = 0;
    for i in range(0,len(data)):
        end = start + data[i].shape[0]
        
        for k in range(0,pred.shape[1]):
            out[i,k] = reducerfunc(pred[start:end,k])
        
        start = start + data[i].shape[0]
        
    return out