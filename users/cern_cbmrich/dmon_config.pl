#This a an example configuration file. Copy this file to your user directory and give 
#start.pl a link to this file as first argument.

#Scripts to start & order of icons in the Overview
activeScripts => [['time','ping','-','-','daqop'],
                  ['numfee','temperature','reftime','billboard','mbs'],
                  ['trgrate','datarate','deadtime','-','-'],
                  ['heatmaprich','padiwatemp','padiwaonline','currents','-'],
                  ['cbmnetlink','cbmnetdata','cbmnetsync','-','-'],],
                  
#Names to be shown in left column of Overview (max 4 letters!)
qaNames => ['sys','main','rate','Pdwa','CNet','-'],                  

#Expected number of FPGAs in system
NumberOfFpga => 90,       

#The address of the individual boards
CtsAddress   => 0x7005,   
PadiwaBroadcastAddress => 0xfe4c,

PadiwaTrbAdresses => [0x0010,0x0011,0x0012,0x0013,
                      0x0020,0x0021,0x0022,0x0023,
                      0x0030,0x0031,0x0032,0x0033,
                      0x0040,0x0041,0x0042,0x0043,
                      0x0050,0x0051,0x0052,0x0053,
                      0x0060,0x0061,0x0062,0x0063,
                      0x0070,0x0071,0x0072,0x0073,
                      0x0080,0x0081,0x0082,0x0083,
                      0x0090,0x0091,0x0092,0x0093,
                      0x00a0,0x00a1,0x00a2,0x00a3,
                      0x00b0,0x00b1,0x00b2,0x00b3,
                      0x00c0,0x00c1,0x00c2,0x00c3,
                      0x00d0,0x00d1,0x00d2,0x00d3,
                      0x00e0,0x00e1,0x00e2,0x00e3,
                      0x00f0,0x00f1,0x00f2,0x00f3,
                      0x0100,0x0101,0x0102,0x0103],

HubTrbAdresses =>  [0x7005,0x7000,0x7001,0x7002,0x7003,
                    0x0015,
                    0x0025,
                    0x0035,
                    0x0045,
                    0x0055,
                    0x0065,
                    0x0075,
                    0x0085,
                    0x0095,
                    0x00a5,
                    0x00b5,
                    0x00c5,
                    0x00d5,
                    0x00e5,
                    0x00f5,
                    0x0105,
                    0x0115],

BillboardAddress => 0x0112,
MBSAddress => 0x0112,
                    
#Addresses of all TDCs. Either single or broadcast addresses
TdcAddress   => [0xfe4c,0xfe4e,0x7005],  

TrbIP => ["192.168.0.29",
          "192.168.0.47",
          "192.168.0.56",
          "192.168.0.57",
          "192.168.0.59",
          "192.168.0.72",
          "192.168.0.73",
          "192.168.0.74",
          "192.168.0.78",
          "192.168.0.83",
          "192.168.0.84",
          "192.168.0.89",
          "192.168.0.97",
          "192.168.0.99",
          "192.168.0.101",
          "192.168.0.102",
          "192.168.0.104",
          "192.168.0.105"],



#User directory
UserDirectory => '/home/hadaq/trbsoft/daqtools/users/cern_cbmrich/'
