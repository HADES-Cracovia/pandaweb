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
#export DAQOPSERVER=localhost

trbcmd reset

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

trbcmd w 0xff7f 0x830e 0x10


~/trbsoft/daqtools/tools/loadregisterdb.pl register_configgbe.db
~/trbsoft/daqtools/tools/loadregisterdb.pl register_configgbe_ip.db

##################################################
## Configure TDCs
##################################################
#trbcmd w 0xfe4c 0xc801 0x000f0005 ## trigger window enable & trigger window width    
trbcmd w 0xfe4c 0xc800 0x00002000 ## Triggered mode
#trbcmd w 0xfe4c 0xc800 0x00003000 ## Triggerless   mode
#trbcmd w 0xfe4c 0xc801 0x000f0005 ## trigger window enable & trigger window width

#trbcmd w 0xfe4c 0xc800 0x00000001 ## logic analyser control register
#trbcmd w 0xfe4c 0xc800 0x00001001 ## 2014-10-02 disable the "triggered mode"
trbcmd w 0xfe4c 0xc801 0x80620062 ##  triggerwindow +/-490ns ;5ns granularity
#trbcmd w 0xfe4c 0xc801 0x801e001e ##  triggerwindow +/-150ns ;5ns granularity
trbcmd w 0xfe4c 0xc802 0xffffffff ## channel 01-32 enable
trbcmd w 0xfe4c 0xc803 0x0000ffff ## channel 33-64 enable
trbcmd w 0xfe4c 0xc804 0x0000007c ## data transfer limit


#trbcmd w 0x1510 0xc800 0x00000001 ## logic analyser control register
#trbcmd w 0x1510 0xc800 0x00001001 ## 2014-10-02 disable the "triggered mode"
#trbcmd w 0x1510 0xc801 0x80620062 ##  triggerwindow +/-490ns ;5ns granularity
#trbcmd w 0xfe4c 0xc802 0xffffffff ## channel 01-32 enable
#trbcmd w 0x1510 0xc804 0x00000080 ## data transfer limit for 0x1510

##################################################
## Other Settings
##################################################
# Reset trigger logic - only a workaround for a bug
#trbcmd w 0xffff 0x20 0x33

#~/trbsoft/daqtools/users/gsi_dirc/prepare_padiwa2015.sh

~/trbsoft/daqtools/users/gsi_dirc/prepare_padiwas_invert_leds.pl --endpoints=0x2000-0x209,0x2010-0x2019 --chains=0..2 --invert=0xffff

# aug2014: no SciFis
#~/trbsoft/daqtools/users/gsi_dirc/prepare_padiwas_invert_leds.pl "0x010 0x011 0x012 0x013 0x110 0x111 0x112 0x113 0x210 0x211 0x212 0x213"

# enable used channels
#echo "- turn on/off TDC-channels"

#~/trbsoft/daqtools/tools/loadregisterdb.pl register_config_tdc.db
#~/trbsoft/daqtools/tools/loadregisterdb.pl register_config_tdc_scifi_mcp1.db
#~/trbsoft/daqtools/tools/loadregisterdb.pl register_config_tdc_scifi_mcp2.db
#echo "-done"

# disable all channels
#trbcmd w 0xfe4c 0xc802 0x00000000
#trbcmd w 0xfe4c 0xc803 0x00000000

# timeouts
trbcmd w 0xfffe 0xc5 0x800050ff

# pulser #1 to 1k Hz
#trbcmd w 0x8000 0xa140 0x0001869f
trbcmd w 0x7999 0xa150 0x000007cf

# pulser enable
#trbcmd setbit 0x7999 0xa101 0x2
#trbcmd clearbit 0x8000 0xa101 0x3

# divert TDC inputs to the CTS for trigger
echo "- divert TDC inputs to the CTS for trigger";
# trbcmd setbit 0xfe4c 0xcf00 0x1 



#trbcmd setbit 0x8000 0xa1d4 0x10000 ## ???

# set proto MCP 0-14 thresholds
echo "- loading proto MCP-PMT 0-14 thresholds from old scan with 1mV delta..."
cd ~/trbsoft/daqtools/thresholds/
# july ./load_thresh_orig.sh  # 1mV
# switch 8/27 ./load_thresh_aug2014.sh  # 4mV for first few days
## ./load_thresh_sep2014-2mV.sh  # 2mV starting evening Sep 8
###./load_thresh_sep2014-2mV-new.sh  # 2mV starting evening Sep 9
###./load_thresh_2015.sh  # 2mV starting evening Sep 10
# ./load_thresh_scifi.sh # 3mV

#set MCPTOF thresholds
# 2015 echo "- loading proto MCP-TOF thresholds..."
# 2015cd ~/trbsoft/daqtools/thresholds/


# Finger weg Fred!

#                        TOF2 TOF2out TOF1 TOF1out
## 2015 ./load_thresh_mcptof.sh  1500 1500 1500 1500 

#./write_thresholds.pl MCPTOF_all_thresholds_zero.log -o 0 >> /dev/null
#./write_thresholds.pl MCPTOF_all_thresholds_zero.log -o 1500 >> /dev/null # =75mV after amp
# # special threshold for MCP-out front
#./load_thresh_mcptof.sh  1500 1500   
# ./write_thresholds.pl MCPTOF_all_thresholds_zero_2010.log -o 0x2ee >> /dev/null # =37.5mV after amp


#8103 3
#trbcmd clearbit 0x7999 0xc0 0x7
#trbcmd clearbit 0x7999 0xc1 0x7
#trbcmd clearbit 0x7999 0xc3 0x7

#trbcmd clearbit 0x8103 0xc0 0xf6
#trbcmd clearbit 0x8103 0xc1 0xf6
#trbcmd clearbit 0x8103 0xc3 0xf6
echo "ready to go"

#echo "- setting trigger rate register in TDC";
# trigger rate 1500Hz
#trbcmd w 0x7999 0xa150 0x10000
