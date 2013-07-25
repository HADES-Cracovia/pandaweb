#!/bin/sh
# PATH should already be marked as exported...
#PATH=${HOME}/trbsoft/bin:${PATH}
#PATH=${HOME}/trbsoft/daqdata/bin:${PATH}
#PATH=${HOME}/trbsoft/trbnettools/bin:${PATH}
export TRB3_SERVER=trb060
export DAQOPSERVER=localhost:60


##################################################
## System Reset
##################################################
trbcmd reset


##################################################
## Set addresses
##################################################
./merge_serial_address.pl ~/trbsoft/daqtools/base/serials_trb3.db ~/trbsoft/daqtools/base/addresses_trb3.db  > /dev/null


##################################################
## Configure GbE for DAQ
##################################################
./configure_trb3.sh # central hub configuration to send data via GbE

##################################################
## Configure TDCs
##################################################
trbcmd clearbit 0xfe48 0xc800 0x00001000 ## Triggered   mode
trbcmd setbit   0xfe48 0xc800 0x00001000 ## Triggerless mode


trbcmd w 0xfe48 0xc801 0x000f0005 ## trigger window enable & trigger window width
trbcmd w 0xfe48 0xc802 0x00000000 ## channel 01-31 enable
trbcmd w 0xfe48 0xc803 0x00000000 ## channel 32-63 enable
trbcmd w 0xfe48 0xc804 0x00000010 ## data transfer limit

trbcmd w 0xc000 0xc802 0x00000003 ## Scintilator on

trbcmd w 0xc00c 0xc802 0x00000000 ## padiwa 1 on
trbcmd w 0xc00c 0xc803 0xffffffff ## padiwa 2 on
trbcmd w 0xc00f 0xc802 0xffffffff ## padiwa 3 on
trbcmd w 0xc00f 0xc803 0xffffffff ## padiwa 4 on


##################################################
## Other Settings
##################################################

# remove hub (port 2) from first trb3
#trbcmd clearbit 0x8000 0xc0 0x4
#trbcmd clearbit 0x8000 0xc1 0x4
#trbcmd clearbit 0x8000 0xc3 0x4


## Reset trigger logic - only a workaround for a bug
trbcmd w 0xffff 0x20 0x33

# timeouts
trbcmd w 0xfffe 0xc5 0x800050ff

# pulser #1 to 1k Hz
trbcmd w 0x8000 0xa137 0x0001869f

# pulser enable
#trbcmd setbit 0x8000 0xa101 0x2
trbcmd clearbit 0x8000 0xa101 0x2

trbcmd setbit 0x8000 0xa101 0x40
