#!/bin/bash
# PATH should already be marked as exported...
#PATH=${HOME}/trbsoft/bin:${PATH}
#PATH=${HOME}/trbsoft/daqdata/bin:${PATH}
#PATH=${HOME}/trbsoft/trbnettools/bin:${PATH}
export TRB3_SERVER=trb056:26000 

export TRBNETDPID=$(pgrep trbnetd)

echo "- trbnetd pid: $TRBNETDPID"

if [[ -z "$TRBNETDPID" ]] 
then
    ~/bin/trbnetd -i 56
    #~/trbsoft/trbnettools/binlocal/trbnetd -i 56
fi

#export TRB3_SERVER=trb056
export DAQOPSERVER=localhost:56

echo -n "- number of trb endpoints in the system: "
trbcmd i 0xffff | wc -l


##################################################
## System Reset
##################################################
#trbcmd reset

##################################################
## Set addresses
##################################################
~/trbsoft/daqtools/merge_serial_address.pl ~/trbsoft/daqtools/base/serials_trb3.db ~/trbsoft/daqtools/users/gsi_dirc/addresses_trb3.db  > /dev/null

##################################################
## Configure GbE for DAQ
##################################################
trbcmd w 0xff7f 0x8308 0xffffff     # Trigger counter   

~/trbsoft/daqtools/tools/loadregisterdb.pl register_configgbe.db
~/trbsoft/daqtools/tools/loadregisterdb.pl register_configgbe_ip.db

##################################################
## Configure TDCs
##################################################
#trbcmd w 0xfe48 0xc801 0x000f0005 ## trigger window enable & trigger window width    
#trbcmd w 0xfe48 0xc800 0x00002000 ## Triggered mode
#trbcmd w 0xfe48 0xc800 0x00003000 ## Triggerless   mode
#trbcmd w 0xfe48 0xc801 0x000f0005 ## trigger window enable & trigger window width

trbcmd w 0xfe48 0xc800 0x00000001 ## logic analyser control register
trbcmd w 0xfe48 0xc801 0x80620062 ##  triggerwindow +/-490ns ;5ns granularity
trbcmd w 0xfe48 0xc802 0x00000000 ## channel 01-32 enable
trbcmd w 0xfe48 0xc803 0x00000000 ## channel 33-64 enable
trbcmd w 0xfe48 0xc804 0x00000080 ## data transfer limit

##################################################
## Other Settings
##################################################
# Reset trigger logic - only a workaround for a bug
#trbcmd w 0xffff 0x20 0x33


~/trbsoft/daqtools/users/gsi_dirc/prepare_padiwas_invert_leds.pl "0x010 0x011 0x012 0x013 0x110 0x111 0x112 0x113 0x210 0x211 0x212 0x213 0x310 0x311 0x312 0x313 0x410 0x411 0x412 0x413 0x510 0x511 0x512 0x513 0x610 0x611 0x612 0x613 0x710 0x711 0x712 0x713 0x810 0x811 0x812 0x813 0x910 0x911 0x912 0x913 0x1010 0x1011 0x1012 0x1013 0x1110 0x1111 0x1112 0x1113 0x1210 0x1211 0x1212 0x1213 0x1310 0x1311 0x1312 0x1313 0x1410 0x1411 0x1412 0x1413"

# enable used channels
echo "- turn on/off TDC-channels"

~/trbsoft/daqtools/tools/loadregisterdb.pl register_config_tdc.db


# disable all channels
#trbcmd w 0xfe48 0xc802 0x00000000
#trbcmd w 0xfe48 0xc803 0x00000000

# timeouts
trbcmd w 0xfffe 0xc5 0x800050ff

# pulser #1 to 1k Hz
#trbcmd w 0x8000 0xa140 0x0001869f

# pulser enable
#trbcmd setbit 0x8000 0xa101 0x2
#trbcmd clearbit 0x8000 0xa101 0x3

# divert TDC inputs to the CTS for trigger
echo "- divert TDC inputs to the CTS for trigger";
trbcmd setbit 0xfe48 0xcf00 0x1 


echo "- setting trigger rate register in TDC";
# trigger rate 150Hz
trbcmd w 0x7999 0xa150 0x100000

#trbcmd setbit 0x8000 0xa1d4 0x10000 ## ???

# set proto MCP 0-14 thresholds
echo "- loading proto MCP-PMT 0-14 thresholds..."
cd ~/trbsoft/daqtools/thresholds/
./load_thresh.sh

#set MCPTOF thresholds
echo "- loading proto MCP-TOF thresholds..."
cd ~/trbsoft/daqtools/thresholds/
./write_thresholds.pl MCPTOF_all_thresholds_zero.log -o 0 >> /dev/null
./write_thresholds.pl MCPTOF_all_thresholds_zero.log -o 1500 >> /dev/null # =75mV after amp


#8103 3
#trbcmd clearbit 0x7999 0xc0 0x7
#trbcmd clearbit 0x7999 0xc1 0x7
#trbcmd clearbit 0x7999 0xc3 0x7

#trbcmd clearbit 0x8103 0xc0 0xf6
#trbcmd clearbit 0x8103 0xc1 0xf6
#trbcmd clearbit 0x8103 0xc3 0xf6
echo "ready to go"
