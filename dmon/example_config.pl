#This a an example configuration file. Copy this file to your user directory and give 
#start.pl a link to this file as first argument.


activeScripts => [['time','-','-','-','daqop'],
                  ['numfee','temperature','-','-','-'],
                  ['trgrate','-','-','-','-'],
                  ['-','-','-','-','-'],],

qaNames => ['system','main','trigger','-','-','-'],                  

NumberOfFpga => 11,       #Expected number of FPGAs in system
CtsAddress   => 0x8000,   #The address of the CTS