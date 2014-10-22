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
~/trbsoft/daqtools/merge_serial_address.pl ~/trbsoft/daqtools/base/serials_trb3.db ~/trbsoft/daqtools/users/cern_cbmrich/addresses_trb3.db  > /dev/null

##################################################
## Configure GbE for DAQ
##################################################
trbcmd w 0xff7f 0x8308 0xffffff     # Trigger counter   

echo "XXX: Running script loadregisterdb.pl register_configgbe.db"
~/trbsoft/daqtools/tools/loadregisterdb.pl register_configgbe.db

echo "XXX: Running script loadregisterdb.pl register_configgbe_ip.db"
~/trbsoft/daqtools/tools/loadregisterdb.pl register_configgbe_ip.db

##################################################
## Configure TDCs
##################################################
#trbcmd w 0xfe48 0xc801 0x000f0005 ## trigger window enable & trigger window width    
#trbcmd w 0xfe48 0xc800 0x00002000 ## Triggered mode
#trbcmd w 0xfe48 0xc800 0x00003000 ## Triggerless   mode
#trbcmd w 0xfe48 0xc801 0x000f0005 ## trigger window enable & trigger window width

trbcmd w 0xfe48 0xc800 0x00001001 ## logic analyser control register #tiggerless
trbcmd w 0xfe48 0xc801 0x80620062 ##  triggerwindow +/-490ns ;5ns granularity
trbcmd w 0xfe48 0xc802 0xffffffff ## channel 01-32 enable
trbcmd w 0xfe48 0xc803 0x00000000 ## channel 33-64 enable
trbcmd w 0xfe48 0xc804 0x00000080 ## data transfer limit


#trbcmd w 0x1510 0xc800 0x00001001 ## logic analyser control register
#trbcmd w 0x1510 0xc801 0x80620062 ##  triggerwindow +/-490ns ;5ns granularity
#trbcmd w 0x1510 0xc802 0x00000000 ## channel 01-32 enable
#trbcmd w 0x1510 0xc803 0x00000000 ## channel 33-64 enable
#trbcmd w 0x1510 0xc804 0x00000080 ## data transfer limit

##################################################
## Other Settings
##################################################
# Reset trigger logic - only a workaround for a bug
#trbcmd w 0xffff 0x20 0x33

echo "XXX: Running prepare padiwas invert leds"
./prepare_padiwas_invert_leds.pl \
"0x0010 0x0011 0x0012 0x0013 \
0x0020 0x0021 0x0022 0x0023 \
0x0030 0x0031 0x0032 0x0033 \
0x0040 0x0041 0x0042 0x0043 \
0x0050 0x0051 0x0052 0x0053 \
0x0060 0x0061 0x0062 0x0063 \
0x0070 0x0071 0x0072 0x0073 \
0x0080 0x0081 0x0082 0x0083 \
0x0090 0x0091 0x0092 0x0093 \
0x00a0 0x00a1 0x00a2 0x00a3 \
0x00b0 0x00b1 0x00b2 0x00b3 \
0x00c0 0x00c1 0x00c2 0x00c3 \
0x00d0 0x00d1 0x00d2 0x00d3 \
0x00e0 0x00e1 0x00e2 0x00e3 \
0x00f0 0x00f1 0x00f2 0x00f3 \
0x0100 0x0101 0x0102 0x0103 "
echo "done..."

# enable used channels
echo "- turn on/off TDC-channels"
~/trbsoft/daqtools/tools/loadregisterdb.pl register_config_tdc.db
echo "...done"


# disable all channels
#trbcmd w 0xfe48 0xc802 0x00000000
#trbcmd w 0xfe48 0xc803 0x00000000

# timeouts
echo "Setting timeouts"
trbcmd w 0xfffe 0xc5 0x800050ff

# pulser #1 to 1k Hz
#trbcmd w 0x8000 0xa140 0x0001869f

echo "- setting trigger rate register in TDC";
# trigger rate 150Hz
trbcmd w 0x7005 0xa150 0x100000

# pulser enable
trbcmd setbit 0x7005 0xa101 0x2
#trbcmd clearbit 0x8000 0xa101 0x3

# divert TDC inputs to the CTS for trigger
echo "- divert TDC inputs to the CTS for trigger";
trbcmd setbit 0xfe48 0xcf00 0x1 



#trbcmd setbit 0x8000 0xa1d4 0x10000 ## ???


#set MAPMT Thresholds
thresholdfile="thresholds_2310_full_offset0.thr"
offset="100"
echo
echo "loading MAPMT thresholds: ${thresholdfile}"
echo "offset is ${offset}   (200=1mv on input)"
../../thresholds/write_thresholds.pl $thresholdfile -o $offset

#8103 3
#trbcmd clearbit 0x7005 0xc0 0x7
#trbcmd clearbit 0x7005 0xc1 0x7
#trbcmd clearbit 0x7005 0xc3 0x7

#trbcmd clearbit 0x8103 0xc0 0xf6
#trbcmd clearbit 0x8103 0xc1 0xf6
#trbcmd clearbit 0x8103 0xc3 0xf6
echo "ready to go"
