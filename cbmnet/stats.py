import numpy as np

def slopeWithoutAvg(X):
   slope = X[1:]-X[:-1]
   return slope - np.average(slope)

def slope(X):
   return X[1:] - X[:-1]