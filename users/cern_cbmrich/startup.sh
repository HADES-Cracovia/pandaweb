#!/bin/bash
# PATH should already be marked as exported...
#PATH=${HOME}/trbsoft/bin:${PATH}
#PATH=${HOME}/trbsoft/daqdata/bin:${PATH}
#PATH=${HOME}/trbsoft/trbnettools/bin:${PATH}
export TRB3_SERVER=trb056:26000 

export TRBNETDPID=$(pgrep trbnetd)

echo "- trbnetd pid: $TRBNETDPID"

# if [[ -z "$TRBNETDPID" ]] 
# then
#     #~/bin/trbnetd -i 56
#     #~/trbsoft/trbnettools/binlocal/trbnetd -i 56
# fi

#export TRB3_SERVER=trb056
export DAQOPSERVER=10.160.0.77:56


##################################################
## System Reset
##################################################
echo "Doing reset"
perl -e 'for(my $i=0; $i < 5; $i++) {`trbcmd reset`; my $n = `trbcmd i 0xffff | wc -l`; exit if $n == 90; print "found only $n fpgas. try it again";} print "Give up\n"'

echo -n "- number of trb endpoints in the system: "
trbcmd i 0xffff | wc -l

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

trbcmd w 0xfe4c 0xc800 0x00001001 ## logic analyser control register #tiggerless
trbcmd w 0xfe4c 0xc801 0x00620062 ## no triggerwindow +/-490ns ;5ns granularity
trbcmd w 0xfe4c 0xc804 0x00000080 ## data transfer limit (0x80 = off)

trbcmd w 0xfe4a 0xc800 0x00001001 ## logic analyser control register #tiggerless
trbcmd w 0xfe4a 0xc801 0x00620062 ## no triggerwindow +/-490ns ;5ns granularity
trbcmd w 0xfe4a 0xc804 0x00000080 ## data transfer limit (0x80 = off)


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
0x0100 0x0101 0x0102 0x0103 0x111"
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
# trigger rate 10kHz
trbcmd w 0x7005 0xa14e 0x00002710  # trg_pulser_config0: low_duration=  10 KHz
trbcmd w 0x7005 0xa14f 0x000f4240  # trg_pulser_config1: low_duration= 100  Hz
trbcmd w 0x7005 0xa150 0x05f5e0f0  # trg_pulser_config2: low_duration= ~ 1 Hz

trbcmd w 0x7005 0xa155 0x11111e11  # _trg_trigger_types0: 
                            # type0=0x1_physics_trigger, type1=0xe_status_information_trigger
                            # type2=0xe_status_information_trigger, type3=0x1_physics_trigger
                            # type4=0x1_physics_trigger, type5=0x1_physics_trigger
                            # type6=0x1_physics_trigger, type7=0x1_physics_trigger

trbcmd w 0x7005 0xa138 0x000f0102  # trg_coin_config0: 
                            # coin_mask=0000 0010, inhibit_mask=0000 0001
                            # window=15
trbcmd w 0x7005 0xa139 0x000f0408  # trg_coin_config1: 
                            # coin_mask=0000 1000, inhibit_mask=0000 0100
                            # window=15

trbcmd w 0x7005 0xa13b 0x00000008  # trg_input_mux0: input=jin1[0]                            
trbcmd w 0x7005 0xa13c 0x00000016  # trg_input_mux1: input=itc[0]                            
trbcmd w 0x7005 0xa13d 0x00000008  # trg_input_mux2: input=jin1[0]                            
trbcmd w 0x7005 0xa13e 0x00000017  # trg_input_mux3: input=itc[1]
                            
trbcmd w 0x7005 0xa124 0x00000000  # trg_input_config0: delay=0, invert=false, override=off, spike_rej=0
trbcmd w 0x7005 0xa125 0x00000000  # trg_input_config1: delay=0, invert=false, override=off, spike_rej=0
trbcmd w 0x7005 0xa126 0x00000100  # trg_input_config2: delay=0, invert=true, override=off, spike_rej=0
trbcmd w 0x7005 0xa127 0x00000000  # trg_input_config3: delay=0, invert=false, override=off, spike_rej=0

trbcmd w 0x7005 0xa009 0x00000011  # cts_readout_config: 
                            # channel_cnt=false, idle_dead_cnt=false, input_cnt=true
                            # timestamp=true, trg_cnt=false

# billboard
trbcmd w 0x0112 0xb01e 0  # include billboard info with e-trigger

#cbmnet
trbcmd w 0x7005 0xa800 0x3   # enable CBMNet AND GbE
trbcmd w 0x7005 0xa901 62500 # enable sync pulser with 2 khz ... prob. dont need it, but better safe thEn sorry

# pulser enable
#trbcmd setbit 0x7005 0xa101 0x1
#trbcmd clearbit 0x8000 0xa101 0x3

# divert TDC inputs to the CTS for trigger
echo "- divert TDC inputs to the CTS for trigger";
trbcmd setbit 0xfe4c 0xcf00 0x1 
trbcmd setbit 0xfe4a 0xcf00 0x1 



#trbcmd setbit 0x8000 0xa1d4 0x10000 ## ???


#set MAPMT Thresholds
#thresholdfile="thresh/stdthresh.thr"
#thresholdfile="thresh/dummythresholds.thr"
#offset="100"
echo
echo "loading MAPMT thresholds: ${thresholdfile}"
echo "offset is ${offset}   (200=1mv on input)"
../../thresholds/write_thresholds.pl thresh/current_thresholds.thr -o 200

echo "Loading Padiwa Amps Settings"
/home/hadaq/trbsoft/daqtools/padiwa.pl 0x111 0 invert 0xaaaa
/home/hadaq/trbsoft/daqtools/padiwa.pl 0x113 0 invert 0xaaaa
../../thresholds/write_thresholds.pl thresh/thresholds_padiwa_amps.thr


echo "Disable noisy pixel in Padiwa"
/home/hadaq/trbsoft/daqtools/padiwa.pl 0x073 0 disable 0x0001

#8103 3
#trbcmd clearbit 0x7005 0xc0 0x7
#trbcmd clearbit 0x7005 0xc1 0x7
#trbcmd clearbit 0x7005 0xc3 0x7

#trbcmd clearbit 0x8103 0xc0 0xf6
#trbcmd clearbit 0x8103 0xc1 0xf6
#trbcmd clearbit 0x8103 0xc3 0xf6

# trbcmd setbit 0x7005 0xa00c 0x80000000

echo "Wait a sec (http://goo.gl/bdWW1g)"
sleep 1
trbcmd w 0x7005 0xa101 0xffff6004  # trg_channel_mask: edge=1111 1111 1111 1111, mask=0110 0000 0000 0100

echo "Trigger activated. I'm done"


