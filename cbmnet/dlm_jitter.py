import datetime
import glob
from hldLib import *
import numpy as np
from stats import *
import os

noEvents = 10000000
counter = 0
netDLMChan = 1
pinDLMChan = 4

epoch = 0
epochTimeInNs = 0.0

calibDataTDC = np.load("calib.npy")

latencies = [[]]
netTimeBuf = []
pinTimeBuf = []
idle = 0

def analyseCTSSSE(ssEvt, evt, counter):
  global epochTimeInNs, eventTimeInCBM
  global calibDataTDC
  global idle
  global netDLMChan, pinDLMChan
  global netTimeBuf, pinTimeBuf
  
  cts, remain = extractCTS(ssEvt[1])
  sync, tdc = extractSync(remain)
  assert(len(sync) in {1, 5, 11})
  
  channels, epochTimeInNs = interpretTDCData(tdc, calibDataTDC, epochTimeInNs)
  
  netTimeBuf += channels.get(netDLMChan, [])
  pinTimeBuf += channels.get(pinDLMChan, [])
  
  if 0==len(channels.get(netDLMChan, [])) or 0==len(channels.get(pinDLMChan, [])):
    if len(netTimeBuf) and len(pinTimeBuf):
      idle += 1
      
    if idle >= 1000:
      netTime = np.array( netTimeBuf )
      
      for pinTime in pinTimeBuf:
        interval = np.min( np.abs( netTime - pinTime ) )
        if interval < 5000:
          latencies[-1].append( interval )
      
      idle = 0
      print len(pinTimeBuf), len(netTimeBuf)
      print "start new block, old contained %d matches with avg %f" % (len(latencies[-1]), np.average(latencies[-1]))
      latencies.append([])
      netTimeBuf = []
      pinTimeBuf = []
      
  else:
    idle = 0
    
         
files = glob.glob("/local/mpenschuck/hldfiles/*.hld")
files.sort()
#files.pop()
#files.pop()
print "Read file ", files[-1]
callbacks = {0x7005: analyseCTSSSE}
counter = iteratorOverHld(files[-1], callbacks, noEvents)
      
print "Processed %d events, found %d matches in %d blocks" % (counter, sum((len(x) for x in latencies)), len(latencies))

stats = np.zeros ( (len(latencies),4) )
i = 0
for block in latencies:
  if len(block) < 500: continue
  times = np.array( block )
  avgInterval = np.average(times)
  stdInterval = np.std(times)
  
  stats[i] = [i, times.shape[0], avgInterval, stdInterval]

  print "Avg: %f ns, Std: %f ns" % (avgInterval, stdInterval)
  np.savetxt("data/dlm_jitter.txt", np.vstack([times, times - avgInterval]).T )
  text_file = open("data/dlm_jitter.label", "w")
  text_file.write('labelText = "Events: %d\\nAvg: %.2f ns\\nRMS: %.2f ps"' % (times.shape[0], avgInterval, stdInterval * 1000) )
  text_file.close()
  
  os.system("gnuplot dlm_jitter.gp")
  i+=1
  os.system("mv data/dlm_jitter.png data/dlm_jitter%04d.png" % i)

np.savetxt("data/dlm_jitter_blocks.txt", stats[:i])
