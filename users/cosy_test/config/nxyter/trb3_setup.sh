#!/bin/sh

echo "Loading nxyter read-out configuration"

case $1 in
	0x38*)
		board=$1
		;;
	*)
		echo "Wrong board!"
		exit
		;;
esac



# i2c_sm_reset
trbcmd w $board 0x8100 0x01
# i2c_reg_reset_start
trbcmd w $board 0x8101 0x01

# Write nxsetup.dat to memory and transfer to nx-i2c-registers
trbcmd wm $board 0x8200 0 nxsetup_$board.dat

#trbcmd w $board 0x8212 150 # threshold, load from dat file

# nx_ts_reset_start
trbcmd w $board 0x8102 0x01

# reset counters, flush FIFO
echo "clear data fifo"
trbcmd rm $board 0x8600 4000 2>/dev/null

# Set readout Mode
trbcmd w $board 0x8400 0x00   # 0: normal mode 4: no TS Window mode
trbcmd w $board 0x8401 0      # window  offset 200ns
trbcmd w $board 0x8402 250    # window width 800ns
trbcmd w $board 0x8403 125    # CTS-Delay 400ns

# Decoder Settings
trbcmd w $board 0x8120 0      # reset all counters

# Enable nxyter
trbcmd w $board 0x8103 0

#Debugging to test ADC alignment / reset feature
# sleep 1;
# trbcmd w $board 0x8501 1

