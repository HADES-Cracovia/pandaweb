#!/bin/bash
# PATH should already be marked as exported...
#PATH=${HOME}/trbsoft/bin:${PATH}
#PATH=${HOME}/trbsoft/daqdata/bin:${PATH}
#PATH=${HOME}/trbsoft/trbnettools/bin:${PATH}
export TRB3_SERVER=trb113:26000 

export TRBNETDPID=$(pgrep trbnetd)

echo "- trbnetd pid: $TRBNETDPID"

if [[ -z "$TRBNETDPID" ]] 
then
    ~/bin/trbnetd -i 113
    #~/trbsoft/trbnettools/binlocal/trbnetd -i 56
fi

#export TRB3_SERVER=trb056


export DAQOPSERVER=localhost:113
#export DAQOPSERVER=localhost

echo -n "- number of trb endpoints in the system: "
trbcmd i 0xffff | wc -l

##################################################
## System Reset
##################################################
#trbcmd reset

##################################################
## Set addresses
##################################################
#~/trbsoft/daqtools/merge_serial_address.pl ~/trbsoft/daqtools/base/serials_trb3.db ~/trbsoft/daqtools/users/gsi_dirc/addresses_trb3.db  > /dev/null
merge_serial_address.pl ~/trbsoft/daqtools/base/serials_trb3.db ~/trbsoft/daqtools/base/addresses_trb3.db  > /dev/null

##################################################
## Configure GbE for DAQ
##################################################
trbcmd w 0xff7f 0x8308 0xffffff     # Trigger counter   

trbcmd w 0xff7f 0x830e 0x10

~/trbsoft/daqtools/tools/loadregisterdb.pl register_configgbe.db
~/trbsoft/daqtools/tools/loadregisterdb.pl register_configgbe_ip.db

echo "ethernet registers configured"

##################################################
## Configure TDCs
##################################################
#trbcmd w 0xfe48 0xc801 0x000f0005 ## trigger window enable & trigger window width    
#trbcmd w 0xfe48 0xc800 0x00002000 ## Triggered mode
#trbcmd w 0xfe48 0xc800 0x00003000 ## Triggerless   mode
#trbcmd w 0xfe48 0xc801 0x000f0005 ## trigger window enable & trigger window width

trbcmd w 0xfe4c 0xc800 0x00001001 ## logic analyser control register
trbcmd w 0xfe4c 0xc801 0x8002000a ##  triggerwindow -50/+10ns ;5ns granularity
#trbcmd w 0xfe48 0xc801 0x801e001e ##  triggerwindow +/-150ns ;5ns granularity
trbcmd w 0xfe4c 0xc802 0x00000000 ## channel 01-32 enable

trbcmd w 0xfe4c 0xc803 0x00000000 ## channel 33-64 enable
trbcmd w 0xfe4c 0xc804 0x00000080 ## data transfer limit

trbcmd w 0xc003 0xc802 0x1 ## channel 01-32 enable
#trbcmd w 0xc001 0xc802 0xffffffff ## channel 01-32 enable
#trbcmd w 0xc003 0xc802 0xffffffff ## channel 01-32 enable
#trbcmd w 0xc010 0xc802 0xffffffff ## channel 01-32 enable
#trbcmd w 0xc001 0xc802 0xffffffff ## channel 01-32 enable

# timeouts
trbcmd w 0xfffe 0xc5 0x800050ff

# pulser #1 to 1k Hz
#trbcmd w 0x8000 0xa140 0x0001869f

# pulser enable
trbcmd setbit 0x8000 0xa101 0x2
#trbcmd clearbit 0x8000 0xa101 0x3

# divert TDC inputs to the CTS for trigger
echo "- divert TDC inputs to the CTS for trigger";
trbcmd setbit 0xfe4c 0xcf00 0x1 

echo "CTS: enable trigger input0 from TDC3"
trbcmd setbit 0x8000 0xa14d 0x10000

echo "ready to go"

#echo "- setting trigger rate register in TDC";
# trigger rate 10000Hz
trbcmd w 0x8000 0xa150 0x0000270f
