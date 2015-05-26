#This a an example configuration file. Copy this file to your user directory and give 
#start.pl a link to this file as first argument.

#Scripts to start & order of icons in the Overview
activeScripts => [['time','ping','-','-','daqop'],
                  ['numfee','temperature','reftime','trgerrors','-'],
                  ['beamintensity','beammonitors','-','-','-'],
                  ['trgrate','datarate','deadtime','-','-'],
                  ['padiwatemp','padiwaonline','-','-','-'],
                  ['heatmapdirc','heatmapflash','heatmapdiscdirc','-','-'],
                  ['evtbnetmem','eb2','eb3','-','-'],
                  ],
                  
#Names to be shown in left column of Overview (max 4 letters!)
qaNames => ['sys','main','beam','rate','Pdwa','Heat','EB'],                  

#Expected number of FPGAs in system
NumberOfFpga => 58,
NumberOfPadiwa => 87,

#The address of the individual boards
CtsAddress   => 0x7999,   
PadiwaBroadcastAddress => 0xfe4c,

PadiwaTrbAddresses => [0x2000,0x2001,0x2002,0x2003,0x2004,0x2005,0x2006,0x2007,
                       0x2008,0x2009,0x200a,0x200b,0x200c,0x200d,0x200e,0x200f,
                       0x2010,0x2011,0x2012,0x2013,0x2014,0x2015,0x2016,0x2018,
                       0x2019,0x201a,0x201c,0x2024,0x2025,0x2026,0x2027,0x2028],
PadiwaChainMask =>    [0x0007,0x0007,0x0007,0x0007,0x0007,0x0007,0x0007,0x0007,
                       0x0007,0x0007,0x0007,0x0007,0x0007,0x0007,0x0007,0x0007,
                       0x0007,0x0007,0x0007,0x0007,0x0001,0x0003,0x0003,0x0001,
                       0x0003,0x0003,0x0003,0x0007,0x0007,0x0007,0x0007,0x0007],
                       
#0x2020,0x2023, no padiwa
#,0x201d,0x201e,0x201f off
#0x2029,0x202a,0x202b,0x202c,0x202d,0x202e,0x202f
OtherTrbAddresses => [0x7999,0x2020,0x2023,0x202c,0x202d],



HubTrbAddresses =>  [0x8100,0x8101,0x8102,0x8103,0x8000,0X8001,0x8002,0x8003,0x8004,0x8005,0x8006,0x8007,0x8008,0x8009,0x800a,0x800b],

                    
#Addresses of all TDCs. Either single or broadcast addresses
TdcAddress   => [0xfe4c,0xfe48,0xfe4a],  

#IPs of all devices which should react on a ping
TrbIP => [
    "192.168.0.72",
    "192.168.0.99",
    "192.168.0.73",
    "192.168.0.74",
    "192.168.0.104",
    "192.168.0.97",
    "192.168.0.83",
    "192.168.0.89",
    "192.168.0.111",
    "192.168.0.13",
    "192.168.0.77",
    "192.168.0.56"
],

#Channel to read spill intensity from. Give limit for off-spill detection
BeamTRB => 0x202c,
BeamChan => 0xc001,
SpillThreshold => 50,

#Name detectors 
BeamDetectorsTrb  => [0x202c,0x202c,0x202c,0x2014,0x2018],
BeamDetectorsChan => [0xc001,0xc005,0xc003,0xc001,0xc001],
BeamDetectorsName => ['Trig1','Trig2','Laser1','MCP1','MCP2'],
#BeamDetectorsTrb  => [0x0110, 0x0110, 0x0111,0x0110,0x0111,0x0110,0x0113,0x0111,0x0110],
#BeamDetectorsChan => [0xc001, 0xc003, 0xc001,0xc009,0xc005,0xc00b,0xc009,0xc009,0xc005],
#BeamDetectorsName => ['Fngr_d', 'Lead_d', 'C1',  'C1_d', 'C2',  'C2_d', 'Lead1', 'Lead2', 'Hodo'],

#User directory
UserDirectory => '/home/hadaq/trbsoft/daqtools/users/gsi_dirc/',
#PowerSupScript => 'measure_powers.sh' # relative to user dir

#BarrelDirc Heatmap settings
HeatmapDirc => {
  # upper limit for high end of color scale
#  max_count_uclamp => 100000000,
#  max_count_uclamp =>10000,
  max_count_uclamp => 5000,
  # lower limit for high end of color scale
  max_count_lclamp => 10,
  
  # when set to 1 normalization of color scale is instantaneous,
  # when set to 0, normalization has "inertia"
  instant_normalization => 1,
  
  # the inertia of the adaption of the color scale in the unit of 1/(gliding average weight)
  normalization_inertia => 3 
},

HeatmapFlash => {
  # upper limit for high end of color scale
  max_count_uclamp => 200000,
  # lower limit for high end of color scale
  max_count_lclamp => 10,
  
  # when set to 1 normalization of color scale is instantaneous,
  # when set to 0, normalization has "inertia"
  instant_normalization => 1,
  
  # the inertia of the adaption of the color scale in the unit of 1/(gliding average weight)
  normalization_inertia => 3 
},

HeatmapDiscDirc => {
  # upper limit for high end of color scale
  max_count_uclamp => 100000,
##  max_count_uclamp => 100,
  # lower limit for high end of color scale
  max_count_lclamp => 30,
  
  # when set to 1 normalization of color scale is instantaneous,
  # when set to 0, normalization has "inertia"
  instant_normalization => 1,
  
  # the inertia of the adaption of the color scale in the unit of 1/(gliding average weight)
  normalization_inertia => 3 
},

EvtbNetmem => {
  shm_string => "test"
}

