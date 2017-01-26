#This a an example configuration file. Copy this file to your user directory and give 
#start.pl a link to this file as first argument.

#Scripts to start & order of icons in the Overview
activeScripts => [['time','ping','-','-','daqop'],
                  ['numfee','temperature','reftime','',''],
                  ['','','-','',''],
                  ['trgrate','datarate','deadtime','-','-'],
                  ['','','','',''],
                  ['','','','-','-']],
                  
#Names to be shown in left column of Overview (max 4 letters!)
qaNames => ['sys','main','beam','rate','pwr','-','-'],                  

#Expected number of FPGAs in system
NumberOfFpga => 7,

#The address of the individual boards
CtsAddress   => 0xc001,   

HubTrbAdresses =>  [0xfffe],

                    
#Addresses of all TDCs. Either single or broadcast addresses
TdcAddress   => [0xfe51],  

#IPs of all devices which should react on a ping
TrbIP => [
"192.168.102.165",
],


#User directory
UserDirectory => '/home/hadaq/trbsoft/daqtools/users/gsi_rich/',
# PowerSupScript => 'measure_powers.sh' # relative to user dir

