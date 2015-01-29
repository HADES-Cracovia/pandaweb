import struct
import datetime

# iterates over a HLD files yieldling events of the following structure:
#  evt = array(
#   0: dict(size, triggerType, evtNumFile, timestamp, runNum)
#   1: array( #of sub-events
#    array(
#     0: dict(size, subEvtId, trgNum, trgCode)
#     1: array ( #of sub-sub-events
#      array(
#       0: dict(size, subsubEvtId)
#       1: array( data-words )
# )))))
def eventIterator(f):
   f.seek(0)
   pos = 0
   
   while(1):
      # we might need to skip some padding
      assert(f.tell() <= pos)
      f.seek(pos)
      
      evtHdrBuf = f.read(8*4)
      if (len(evtHdrBuf) != 8*4):
         break #eof
   
      hdr = struct.unpack("<" + ("I" * 8), evtHdrBuf)
      if (hdr[1] > 0xf0000): hdr = struct.unpack(">" + ("I" * 8), evtHdrBuf)
      
      evtSize = hdr[0]
      
      pos += evtSize
      if (evtSize % 8):
         pos += 8 - (evtSize % 8)
      
      # decode hdr
      hdrDec = {
         'size': evtSize,
         'triggerType': hdr[2] & 0xffff,
         'evtNumFile': hdr[3],
         'timestamp': datetime.datetime(
                        (hdr[4] >> 16) & 0xff, (hdr[4] >> 8) & 0xff, (hdr[4] >> 0) & 0xff, 
                        (hdr[5] >> 16) & 0xff, (hdr[5] >> 8) & 0xff, (hdr[5] >> 0) & 0xff ),
         'runNum': hdr[6]
      }
      
      # load payload
      subEvents = []
      innerPos = 8*4
      while(innerPos < evtSize):
         subEvtHdrBuf = f.read(4 * 4)
         endian = "<"
         subEvtHdr = struct.unpack("<" + ("I" * 4), subEvtHdrBuf)
         if (subEvtHdr[1] > 0xf0000):
            subEvtHdr = struct.unpack(">" + ("I" * 4), subEvtHdrBuf)
            endian = ">"
         
         subEvtSize = subEvtHdr[0]
         subEvtHdrDec = {
            'size': subEvtSize,
            'subEvtId': subEvtHdr[2] & 0xffff,
            'trgNum': (subEvtHdr[3] >> 8) & 0xffffff,
            'trgCode': subEvtHdr[3] & 0xff
         }
         
         subsubEvents = []
         ssPos = 4*4
         while(ssPos < subEvtSize):
            sseHdrBuf = f.read(4)
            sseHdr = struct.unpack(endian + "I", sseHdrBuf)
            sseSize = ((sseHdr[0] >> 16) & 0xffff) * 4 
            sseHdrDec = {
               'size': sseSize,
               'subsubEvtId': sseHdr[0] & 0xffff
            }
            
            sseBuf = f.read(sseSize)
            sseCont = struct.unpack(endian + ("I" * (sseSize/4)), sseBuf)
            subsubEvents.append( (sseHdrDec, sseCont) )
            
            ssPos += sseSize + 4
         
         subEvents.append( (subEvtHdrDec, subsubEvents) )
         
         innerPos += subEvtSize
         
      yield (hdrDec, subEvents)

def dumpEvt(evt):
   res = str(evt[0]) + "\n"
   for subEvt in evt[1]:
      res += "  " + dumpSubEvt(subEvt).replace("\n", "\n  ") + "\n"
   return res

def dumpSubEvt(sEvt):
   h = sEvt[0]
   res = "subEvtId: 0x%04x, trgNum: % 9d, trgCode: % 4d, size: % 4d\n" % (h['subEvtId'], h['trgNum'], h['trgCode'], h['size'])
   for ssEvt in sEvt[1]:
      res += "  " + dumpSubSubEvt(ssEvt).replace("\n", "\n  ") + "\n"
   return res

def dumpSubSubEvt(ssEvt):
   res = "ID: 0x%04x, Size: %d\n" % (ssEvt[0]['subsubEvtId'], ssEvt[0]['size'])
   res += dumpArray(ssEvt[1])
   return res

def dumpArray(arr):
   res = ""
   for i in range(0, len(arr)):
      if i != 0 and i % 8 == 0: res += "\n"
      res += "  [% 3d] 0x%08x" % (i+1, arr[i])

   return res

def iteratorOverHld(filename, cbs, eventNum = -1):
  i = 0
  with open(filename, "rb") as hld:
    for evt in eventIterator(hld):
      if not len(evt[1]): continue
      for sEvt in evt[1]:
        for ssEvt in sEvt[1]:
          ssid = ssEvt[0]['subsubEvtId']
          if ssid in cbs:
            if callable( cbs[ssid] ):
              cbs[ssid](ssEvt, evt, i)
            else:
              for func in cbs[ssid]:
                func(ssEvt, evt, i)
        
      i += 1
      if (0 < eventNum <= i):
        break
      
  return i

def extractCTS(ssEvtData):
   hdr = ssEvtData[0]
   length = 1 + \
      ((hdr >> 16) & 0xf) * 2 + \
      ((hdr >> 20) & 0x1f) * 2 + \
      ((hdr >> 25) & 0x1) * 2 + \
      ((hdr >> 26) & 0x1) * 3 + \
      ((hdr >> 27) & 0x1) * 1

   if (((hdr >> 28) & 0x3) == 0x1): length += 1
   if (((hdr >> 28) & 0x3) == 0x2): length += 4

   return (ssEvtData[:length], ssEvtData[length:])

def extractSync(ssEvtData):
   hdr = ssEvtData[0]
   assert(hdr >> 28 == 0x1)
   packType = (hdr >> 26) & 0x3
   length = 1
   if (packType == 1): length += 4
   if (packType == 3): length += 10
   
   return (ssEvtData[:length], ssEvtData[length:])


def extractTDC(ssEvtData):
   length = ssEvtData[0]
   assert(length >= len(ssEvtData))
   return (ssEvtData[:length+1], ssEvtData[length:])   

def tdcTimeData(w):
   if not (w & 0x80000000):
      return None
   
   return {
      "coarseTime": (w >> 0) & 0x7ff,
      "edge": (w >> 11) & 1,
      "fineTime": (w >> 12) & 0x3ff,
      "channelNo": (w >> 22) & 0x7f
   }


def interpretTDCData(data, calibDataTDC, epochTimeInNs = 0):
  channels = {}
  for w in data:
    if w & 0x80000000:
      tdcData = tdcTimeData(w)
      chan = tdcData["channelNo"]
      if tdcData["edge"] == 1:# and tdcData["fineTime"] != 0x3ff:
        fineTimeInNs = calibDataTDC[tdcData["channelNo"], tdcData["fineTime"]]
        assert( 0 <= fineTimeInNs <= 5.0 )
        coarseTimeInNs = tdcData["coarseTime"] * 5.0
        tdcTime = coarseTimeInNs - fineTimeInNs + epochTimeInNs
        
        if not chan in channels: channels[chan] = []
        channels[chan].append(tdcTime)
            
    
    elif (w >> 29) == 3: # epoch counter
      epoch = w & 0x0fffffff
      epochTimeInNs = epoch * 10240.0 
      
    elif (w >> 29) == 1: # tdc header
      pass
    elif (w >> 29) == 2: # debug
      pass
    else:
      print "Unknown TDC word type: 0x%08x" % w  

  return channels, epochTimeInNs
