#This a an example configuration file. Copy this file to your user directory and give 
#start.pl a link to this file as first argument.

#Scripts to start & order of icons in the Overview
activeScripts => [['time','ping','-','-','daqop'],
                  ['numfee','temperature','reftime','',''],
                  ['','','-','',''],
                  ['trgrate','datarate','deadtime','-','-'],
                  ['adcvolt','adccurr','','',''],
                  ['','','','-','-']],
                  
#Names to be shown in left column of Overview (max 4 letters!)
qaNames => ['sys','main','beam','rate','pwr','-','-'],                  

#Expected number of FPGAs in system
NumberOfFpga => 10,

#The address of the individual boards
CtsAddress   => 0xc000,   

HubTrbAdresses =>  [0xfffe],

                    
#Addresses of all TDCs. Either single or broadcast addresses
TdcAddress   => [0xfe51],  

#ADC voltage monitoring
AdcCombinerAddress => [0xfe52],
AdcDiRichAddress   => [0xfe51],
AdcTrb3sc          => [0xfe61],

#IPs of all devices which should react on a ping
TrbIP => ['192.168.0.247'],


#User directory
UserDirectory => '/home/hadaq/trbsoft/daqtools/users/frankfurt_test/',
# PowerSupScript => 'measure_powers.sh' # relative to user dir

