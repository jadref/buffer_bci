import sklearn.linear_model
import skwrap

def fit(data, events, mapping):
    global classifier
    classifier = sklearn.linear_model.LinearRegression()
    params = {"fit_intercept" : [True, False], "normalize" : [True, False]}             
    skwrap.fit(data, events, classifier, mapping, params, reducer="mean")
    
def predict(data):
    global classifier    
    return skwrap.predict(data, classifier, reducerdata="mean")
