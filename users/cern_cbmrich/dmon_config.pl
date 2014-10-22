#This a an example configuration file. Copy this file to your user directory and give 
#start.pl a link to this file as first argument.

#Scripts to start & order of icons in the Overview
activeScripts => [['time','-','-','-','daqop'],
                  ['numfee','temperature','reftime','-','-'],
                  ['trgrate','datarate','deadtime','-','-'],
                  ['-','-','-','-','-'],
                  ['-','-','-','-','-'],],
                  
#Names to be shown in left column of Overview (max 4 letters!)
qaNames => ['sys','main','rate','-','-','-'],                  

#Expected number of FPGAs in system
NumberOfFpga => 90,       

#The address of the CTS
CtsAddress   => 0x7999,   

#Addresses of all TDCs. Either single or broadcast addresses
TdcAddress   => [0xfe48,0xfe4e,0x7999],  
