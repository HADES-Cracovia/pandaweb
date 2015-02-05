import datetime
import glob
from hldLib import *
import numpy as np
from stats import *
import os

noEvents = 1000000
counter = 0

timestamps = [] # in us
lastId = None
trgOffset = 0
lastRegNum = None

def analyseMBS(ssEvt, evt, counter):
  global timestamps
  global lastRegNum, lastId, trgOffset
  
  regNum = ssEvt[1][0] &   0x00ffffff
  
  if lastRegNum == regNum: return
  lastRegNum = regNum
  
  inclTime = ssEvt[1][0] & 0x01000000
  error = ssEvt[1][0] &    0x80000000
  
  if (error): print "Error in regNum", regNum
  assert(inclTime)
  
  trgId = trgOffset + (ssEvt[1][2]&0xffff)
  if lastId != None and lastId > trgId:
    trgOffset += 0x10000
    trgId += 0x10000
    
  lastId = trgId
  #print ssEvt[1][1]*5e-3
  
  ts=20*trgId + ssEvt[1][1]*5e-3
  #print ts
  
  timestamps.append( ts )
    
         
files = glob.glob("/local/mpenschuck/hldfiles/*.hld")
files.sort()
print "Read file ", files[-1]
callbacks = {0xf30a: analyseMBS}
counter = iteratorOverHld(files[-1], callbacks, noEvents)
      
print "Processed %d events, found %d timestampts" % (counter, len(timestamps))

timestamps = np.array(timestamps)
sTimestamps = slope(timestamps)

dev = sTimestamps - np.average(sTimestamps)

print 1e3/30.52, np.average(sTimestamps), np.std(sTimestamps), np.max(dev)
