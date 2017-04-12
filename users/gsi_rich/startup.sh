#!/bin/bash

export DAQ_TOOLS_PATH=~/trbsoft/daqtools
export USER_DIR=~/trbsoft/daqtools/users/gsi_rich
export TRB_WEB_DIR=$DAQ_TOOLS_PATH/web

export PATH=$PATH:$DAQ_TOOLS_PATH
export PATH=$PATH:$DAQ_TOOLS_PATH/tools
export PATH=$PATH:$USER_DIR

export TRB3_SERVER=trbp165:26000
export TRBNETDPID=$(pgrep -f "trbnetd -i 165")
#export DAQOPSERVER=hadeb05:84
export DAQOPSERVER=hadesp43:165

echo "- trbnetd pid: $TRBNETDPID"

if [[ -z "$TRBNETDPID" ]] 
then
    ~/trbsoft/trbnettools/bin/trbnetd -i 165
fi

./check_ping.pl --reboot


echo "reset"
./trbreset_loop.pl
sleep 1;

##################################################
## Set addresses
##################################################
merge_serial_address.pl $DAQ_TOOLS_PATH/base/serials_trb3.db $USER_DIR/db/addresses_trb3.db
merge_serial_address.pl $DAQ_TOOLS_PATH/base/serials_dirich.db $USER_DIR/db/addresses_dirich.db
merge_serial_address.pl $DAQ_TOOLS_PATH/base/serials_dirich_concentrator.db $USER_DIR/db/addresses_dirich_concentrator.db


#echo "disable port 6 on hub 0x8841"
#trbcmd clearbit 0x8841 0xc0 0x40
#trbcmd clearbit 0x8841 0xc1 0x40
#trbcmd clearbit 0x8841 0xc3 0x40


echo "GbE settings"
loadregisterdb.pl db/register_configgbe.db
loadregisterdb.pl db/register_configgbe_ip.db

echo "TDC settings"
loadregisterdb.pl db/register_configtdc.db
echo "TDC settings end"

# setup central FPGA - enable peripherial signals
#switchport.pl 0x8841 6 off






# pulser to 100kHz and 50kHz
#trbcmd w 0xc840 0xa156 0x0000270f #10khz pulser 0

#trbcmd w 0xc840 0xa150 0x000003e7 #100khz
#trbcmd w 0xc840 0xa150 0x0001869f #1khz
#trbcmd w 0xc840 0xa150 0x00001387 #20khz
#trbcmd w 0xc840 0xa150 0x00000d04 #30khz
#trbcmd w 0xc840 0xa150 0x000007cf #50khz
#trbcmd w 0xc840 0xa157 0x0000270f #10khz

#trbcmd setbit 0xc840 0xa101 0x2 #enable pulser 0
#trbcmd setbit 0xc840 0xa101 0x2 #enable pulser 1
#trbcmd setbit 0xc840 0xa101 0x20 #enable Addon Multiplexer 1
#trbcmd setbit 0xc840 0xa101 0x8 #enable CTS Addon 0
#trbcmd setbit 0xc840 0xa101 0x200 #enable periph fpga input as trigger


# trigger on TDC channel 1
#trbcmd setbit 0x0810 0xcf00 0x1     #direct TDC input to CTS
#trbcmd setbit 0xc001 0xa14d 0x2     #select F5_COMM input
#trbcmd setbit 0xc840 0xa101 0x200   #enable input at CTS

# set correct timeout: off for channel 0, 1, 2sec for 2
trbcmd w 0xfffe 0xc5 0x50ff

#Dirich-Concentrator: enable reference time from RJ45
trbcmd loadbit 0x8300 0xd580 0x6 0x6

echo "pulser"
# pulser #0 to 10 kHz
#trbcmd w 0xc001 0xa154 0x0000270f  # cts design newer than 2016.09
trbcmd w 0xc001 0xa150 0x0000270f   # 

#echo "trigger type"
# set trigger type to 0x1
#trbcmd setbit 0xc001 0xa155 0x10

echo "pulser enable"
# pulser enable
#trbcmd setbit 0xc001 0xa101 0x1

#trbcmd clearbit 0x1130 0xc801 0x80000000 # disable window
#trbcmd w 0x1130 0xc802 0xffff0000 # enable upper 16 channels for padiwa
#trbcmd w 0x1580 0xc802 0xffffffff # enable upper 16 channels for padiwa


cd ~/trbsoft/daqtools/xml-db
./put.pl Readout 0xfe51 SetMaxEventSize 500
cd $USER_DIR

trbcmd w 0xfe51 0xdf80 0xffffffff # enable monitor counters

#trbcmd w 0x1133 0xc804 0x7c # max number of words
#trbcmd clearbit 0x1133 0xc801 0x80000000 # disable window
#trbcmd w 0x1133 0xc802 0x00000c03 # enable pulser

#trbcmd setbit 0xc001 0xa101 0x8 # enable external trigger in of CTS
trbcmd setbit 0xc001 0xa101 0x1 # enable pulser

