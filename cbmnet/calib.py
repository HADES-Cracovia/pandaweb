import datetime
import glob
from hldLib import *
import numpy as np
from stats import *
import os

noEvents = 10000000
counter = 0
channels = 5
histogram = np.zeros( (channels, 1024), dtype="uint" ) 

def analyseCTSSSE(ssEvt, evt, counter):
  global epochTimeInNs, eventTimeInCBM
  global calibDataTDC
  global idle
  global netDLMChan, pinDLMChan
  
  cts, remain = extractCTS(ssEvt[1])
  sync, tdc = extractSync(remain)
  assert(len(sync) in {1, 5, 11})
  
  for w in tdc:
    if w & 0x80000000:
      data = tdcTimeData(w)
      assert(data['channelNo'] < channels)
      if data['fineTime'] != 0x3ff:
        histogram[ data['channelNo'], data['fineTime'] ] += 1
         
files = glob.glob("/local/mpenschuck/hldfiles/*.hld")
files.sort()
print "Read file ", files[-2]
callbacks = {0x7005: analyseCTSSSE}
counter = iteratorOverHld(files[-1], callbacks, noEvents)
      
print "Processed %d events, found %d fineTimes (%d in smallest channel)" % (counter, np.sum(histogram), np.min(np.sum(histogram, axis=1)))

calib = 5.* np.cumsum(histogram, axis=1).astype('float') / np.sum(histogram, axis=1)[:,np.newaxis]
calib *= 5.0 / calib[:,-1].reshape(-1,1)

np.save("calib.npy", calib)
np.savetxt("data/calib.txt", calib.T)
np.savetxt("data/histogram.txt", histogram.T)