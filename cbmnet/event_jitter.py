from hldLib import *
import glob
import numpy as np

# set-up constants and fetch calibration data
noEvents = 1000000
calibDataTDC = np.load("calib.npy")
trbRefTimeTDCChan = 0
cbmRefTimeTDCChan = 3

# interpret the HLD file
epochTimeInNs = 0.0
eventTimeInCBM = []
def analyseCTSSSE(ssEvt, evt, counter):
  global epochTimeInNs, calibDataTDC, eventTimeInCBM
  global trbRefTimeTDCChan, cbmRefTimeTDCChan
  
  cts, remain = extractCTS(ssEvt[1])
  sync, tdc = extractSync(remain)
  assert(len(sync) in {1, 5, 11})
  
  channels, epochTimeInNs = interpretTDCData(tdc, calibDataTDC, epochTimeInNs)
  
  if (not channels[trbRefTimeTDCChan] or \
      not channels[cbmRefTimeTDCChan] or \
      len(channels[trbRefTimeTDCChan]) != 1 or \
      len(channels[cbmRefTimeTDCChan]) != 1):
    return
  
  eventTimeInCBM.append( 8.0 * sync[2] + channels[trbRefTimeTDCChan][0] - channels[cbmRefTimeTDCChan][0] )

# get file and iterate over it      
files = glob.glob("/local/mpenschuck/hldfiles/ct14290170201.hld")
files.sort()
print "Read file ", files[-1]
callbacks = {0xf3c0: analyseCTSSSE}
counter = iteratorOverHld(files[-1], callbacks, noEvents)

# calculate slope and jitter
print "Found %d events" % counter
eventTimeInCBM = np.array(eventTimeInCBM)
timeBetweenEvents = eventTimeInCBM[1:] - eventTimeInCBM[:-1]
avgInterval = np.average(timeBetweenEvents)
stdInterval = np.std(timeBetweenEvents)

# dump values computed
print "Avg: %f ns, Std: %f ns" % (avgInterval, stdInterval)
np.savetxt("data/event_jitter.txt", np.vstack([timeBetweenEvents, timeBetweenEvents - avgInterval]).T )
text_file = open("data/event_jitter.label", "w")
text_file.write('labelText = "Events: %d\\nAvg: %.2f ns\\nFreq: %.2f KHz\\nRMS: %.2f ps"\n' % (counter, avgInterval, 1e6 / avgInterval, stdInterval * 1000) )
text_file.close()
