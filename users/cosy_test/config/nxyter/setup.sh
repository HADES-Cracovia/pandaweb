#!/bin/sh

echo "Loading nxyter read-out configuration"

# i2c_sm_reset
trbcmd w 0x3800 0x8100 0x01
# i2c_reg_reset_start
trbcmd w 0x3800 0x8101 0x01

# Write nxsetup.dat to memory and transfer to nx-i2c-registers
trbcmd wm 0x3800 0x8200 0 nxsetup.dat

trbcmd w 0x3800 0x8212 150

# nx_ts_reset_start
trbcmd w 0x3800 0x8102 0x01

# reset counters, flush FIFO
echo "clear data fifo"
trbcmd rm 0x3800 0x8600 4000 2>/dev/null

# Set readout Mode
trbcmd w 0x3800 0x8400 0x00   # 0: normal mode 4: no TS Window mode
trbcmd w 0x3800 0x8401 50     # window  offset 200ns
trbcmd w 0x3800 0x8402 200    # window width 800ns
trbcmd w 0x3800 0x8403 100    # CTS-Delay 400ns

# Decoder Settings
trbcmd w 0x3800 0x8120 0       # reset all counters

# Enable nxyter
trbcmd w 0x3800 0x8103 0

#Debugging to test ADC alignment / reset feature
# sleep 1;
# trbcmd w 0x3800 0x8501 1

