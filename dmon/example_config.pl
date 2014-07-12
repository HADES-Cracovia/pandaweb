#This a an example configuration file. Copy this file to your user directory and give 
#start.pl a link to this file as first argument.

#Scripts to start & order of icons in the Overview
activeScripts => [['time','-','-','-','daqop'],
                  ['numfee','temperature','reftime','-','-'],
                  ['trgrate','-','-','-','-'],
                  ['-','-','-','-','-'],],
                  
#Names to be shown in left column of Overview
qaNames => ['system','main','trigger','-','-','-'],                  

#Expected number of FPGAs in system
NumberOfFpga => 11,       

#The address of the CTS
CtsAddress   => 0x8000,   

#Addresses of all TDCs. Either single or broadcast addresses
TdcAddress   => [0xfe48,0xfe4e,0x8000],  