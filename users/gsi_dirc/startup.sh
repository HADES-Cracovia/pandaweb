#!/bin/bash

export PATH=$PATH:~/trbsoft/daqtools/users/gsi_dirc

#trbcmd reset
check_ping.pl --reboot
rc=$?; if [[ $rc != 0 ]]; then echo "exit from startup as not all boards are up"; exit $rc; fi

export TRB3_SERVER=trb056:26000 
export TRBNETDPID=$(pgrep trbnetd)

echo "- trbnetd pid: $TRBNETDPID"

if [[ -z "$TRBNETDPID" ]] 
then
    ~/bin/trbnetd -i 56
fi

export DAQOPSERVER=localhost:56
#export DAQOPSERVER=localhost

trbreset_loop.pl

##################################################
## Set addresses
##################################################
~/trbsoft/daqtools/merge_serial_address.pl ~/trbsoft/daqtools/base/serials_trb3.db ~/trbsoft/daqtools/users/gsi_dirc/addresses_trb3.db  > /dev/null

##################################################
## Configure GbE for DAQ
##################################################
trbcmd w 0xff7f 0x8308 0xffffff     # Trigger counter for startup
trbcmd w 0xff7f 0x830e 0x10

~/trbsoft/daqtools/tools/loadregisterdb.pl register_configgbe.db
~/trbsoft/daqtools/tools/loadregisterdb.pl register_configgbe_ip.db



##################################################
## Configure TDCs
##################################################

# standard TDCs
trbcmd clearbit 0xfe4c 0xc800 0x2000 ## clear bit to reset the epoch and coarse counters
trbcmd w 0xfe4c 0xc800 0x00002000 ## TDC-Control-Register, RTniceM
#trbcmd w 0xfe4c 0xc800 0x00003000 ## Triggerless   mode
#trbcmd w 0xfe4c 0xc801 0x000f0005 ## trigger window enable & trigger window width
#trbcmd w 0xfe4c 0xc800 0x00000001 ## logic analyser control register
#trbcmd w 0xfe4c 0xc800 0x00001001 ## 2014-10-02 disable the "triggered mode"

trbcmd w 0xfe4c 0xc801 0x801e0046 ##  triggerwindow -350...+150ns ;5ns granularity
#trbcmd w 0xfe4c 0xc801 0x80c600c6 ##  triggerwindow +/-990ns ;5ns granularity
#trbcmd w 0xfe4c 0xc801 0x8000001e ##  triggerwindow +/-150ns ;5ns granularity

# Default TDC-channel enable for all channels
trbcmd w 0xfe4c 0xc802 0xffffffff ## channel 01-32 enable
trbcmd w 0xfe4c 0xc803 0x0000ffff ## channel 33-64 enable
trbcmd w 0xfe4c 0xc804 0x0000007c ## data transfer limit

# TOFs time windows
trbcmd w 0x2014 0xc801 0x8000008c
trbcmd w 0x2015 0xc801 0x8000008c
trbcmd w 0x2016 0xc801 0x8000008c
trbcmd w 0x2018 0xc801 0x8000008c
trbcmd w 0x2019 0xc801 0x8000008c
trbcmd w 0x201a 0xc801 0x8000008c
trbcmd w 0x201c 0xc801 0x8000008c
trbcmd w 0x201d 0xc801 0x8000008c


# special Matthias TDCs
#trbcmd clearbit 0xfe48 0xc800 0x2000 ## clear bit to reset the epoch and coarse counters
#trbcmd w 0xfe48 0xc800 0x00002000 ## Triggered mode
#trbcmd w 0xfe48 0xc801 0x80c600c6 ##  triggerwindow +/-990ns ;5ns granularity
#trbcmd w 0xfe48 0xc802 0xffffffff ## channel 01-32 enable
#trbcmd w 0xfe48 0xc803 0xffffffff ## channel 33-64 enable
#trbcmd w 0xfe48 0xc804 0x0000007c ## data transfer limit

# special settings for barrel 
#trbcmd w 0x2000 0xc801 0x8018004b ##  triggerwindow -375ns ... 120ns ;5ns granularity


# AUX TDCs
trbcmd clearbit 0xfe4a 0xc800 0x2000 ## clear bit to reset the epoch and coarse counters
trbcmd w 0xfe4a 0xc800 0x00002000 ## Triggered mode
trbcmd w 0xfe4a 0xc801 0x801e0046 ##  triggerwindow -350...+150ns ;5ns granularity
#trbcmd w 0xfe4a 0xc801 0x80c600c6 ##  triggerwindow +/-990ns ;5ns granularity
trbcmd w 0xfe4a 0xc802 0x00000000 ## channel 33-64 enable
trbcmd w 0x202c 0xc802 0xffffffff ## channel 01-32 enable
trbcmd w 0x202d 0xc802 0xffffffff ## channel 01-32 enable
trbcmd w 0xfe4a 0xc803 0x00000000 ## channel 33-64 enable
trbcmd w 0xfe4a 0xc804 0x0000007c ## data transfer limit



~/trbsoft/daqtools/tools/loadregisterdb.pl register_config_tdc.db


echo -n "- number of trb endpoints in the system after turning off unused tdcs: "
trbcmd i 0xffff | wc -l

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

#20150522 Jan comment
~/trbsoft/daqtools/padiwa.pl 0xfe4c 0 time > /dev/null;~/trbsoft/daqtools/padiwa.pl 0xfe4c 1 time > /dev/null; ~/trbsoft/daqtools/padiwa.pl 0xfe4c 2 time > /dev/null


# Barrel DIRC
# enable stretch prepare_padiwas_invert_leds.pl --endpoints=0x2000-0x2013 --chains=0..2 --invert=0xffff --stretch=0xffff

prepare_padiwas_invert_leds.pl --endpoints=0x2000..0x2013 --chains=0..2 --invert=0xffff 
padiwa_led_off.pl

# Beam
prepare_padiwas_invert_leds.pl --endpoints=0x2014-0x201f --chains=0..2 --invert=0xffff


# disable unused TDCs
# turn off two unused TDCs in HODO

# turn off two unused TDCs in TOF1
switchport.pl 0x8005 3 off

# turn off two unused TDCs in TOF1
switchport.pl 0x8006 3 off


# timeouts
trbcmd w 0xfffe 0xc5 0x800050ff

# divert TDC inputs to the CTS for trigger
#echo "- divert TDC inputs to the CTS for trigger";
# trbcmd setbit 0xfe4c 0xcf00 0x1 
#trbcmd setbit 0x8000 0xa1d4 0x10000 ## ???


cd ~/trbsoft/daqtools/thresholds/
# july ./load_thresh_orig.sh  # 1mV
# switch 8/27 ./load_thresh_aug2014.sh  # 4mV for first few days
## ./load_thresh_sep2014-2mV.sh  # 2mV starting evening Sep 8

## 2015 ./load_thresh_mcptof.sh  1500 1500 1500 1500 

## Barrel DIRC
#./write_thresholds.pl ~/trbsoft/daqtools/users/gsi_dirc/thresh/201505101447.thr -o 600 >> /dev/null # 1.5mV at plug
#./write_thresholds.pl padiwa_threshold_results_20150511_2.log -o 400 > /dev/null # 1mV at plug
# for stretch ./write_thresholds.pl padiwa_threshold_results_20150516_high_stretch_CS.log -o 400 > /dev/null # 1mV at plug
#20150521
#./write_thresholds.pl padiwa_threshold_results_20150516_high_nostretch_CS.log -o 200 > /dev/null 
#./write_thresholds.pl padiwa_threshold_results_20150521_high_nostretch_CS.log -o 200 > /dev/null 
echo "write barrel dirc thresholds"

#./write_thresholds.pl padiwa_threshold_results_sequential_2015_06_25_offset_40_a.log -o 160
#./write_thresholds.pl padiwa_threshold_results_sequential_2015_06_27_offset_40_a.log -o 160
./write_thresholds.pl padiwa_threshold_results_sequential_2015_07_04_offset_40_a.log -o 160

sleep 2

echo "write mcp and scitil thresholds"
#MCP-TOF, SciTils
./write_thresholds.pl mcptof_mcpout_zero.log -o 0 >> /dev/null # =10 mV before amp
./write_thresholds.pl mcptof_pixels_zero.log -o 0 >> /dev/null # =10 mV before amp
./write_thresholds.pl mcptof_scitil_noatt_zero.log -o 0 >> /dev/null # =10 mV before amp
./write_thresholds.pl mcptof_hodo_zero.log -o 0 >> /dev/null # =7 mV before amp
./write_thresholds.pl mcptof_chanmerge_mcpnoamp_zero.log -o 0 >> /dev/null # =7 mV before amp
sleep 2
./write_thresholds.pl mcptof_mcpout_zero.log -o 400 >> /dev/null # =10 mV before amp
./write_thresholds.pl mcptof_pixels_zero.log -o 1500 >> /dev/null # =10 mV before amp
./write_thresholds.pl mcptof_scitil_noatt_zero.log -o 400 >> /dev/null # =10 mV before amp
./write_thresholds.pl mcptof_hodo_zero.log -o 1000 >> /dev/null # =7 mV before amp
./write_thresholds.pl mcptof_chanmerge_mcpnoamp_zero.log -o 400 >> /dev/null # =7 mV before amp


#echo "led off"
#./padiwa_led_off_MT.sh > /dev/null
#20150524 kill noisy pixel by setting 0xffff threshold
# 20150625 - disable kill # echo "turn off noisy pixel"
#./write_thresholds.pl padiwa_killPix.log > /dev/null 


cd -


echo "ready to go"

#echo "- setting trigger rate register in TDC";
# trigger rate 1500Hz
trbcmd w 0x7999 0xa150 0x0001869f
# pulser enable
#trbcmd setbit 0x7999 0xa101 0x2

# enable multiplexer 0
trbcmd setbit 0x7999 0xa101 0x30

trbcmd w 0x7999 0xa150 0x270f  #1kHz pulser
trbcmd w 0x7999 0xa151 0x05f5e100  #1Hz pulser
trbcmd loadbit 0x7999 0xa158 0x00000f00 0x00000d00  #Pulser 1 is calibration


# disable all triggers
#trbcmd setbit 0x7999 0xa00c 0x80000000
