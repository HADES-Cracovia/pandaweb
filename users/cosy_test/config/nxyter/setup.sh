#!/bin/sh

echo "Loading nxyter read-out configuration"

# i2c_sm_reset
trbcmd w 0x3800 0x8100 0x01
# i2c_reg_reset_start
trbcmd w 0x3800 0x8101 0x01

# Write nxsetup.dat to memory and transfer to nx-i2c-registers
trbcmd wm 0x3800 0x8200 0 nxsetup.dat
trbcmd w 0x3800 0x8241 1

#enable Testmode
#trb_i2c w 0x3800 0x08 0x20 0x08  # bit0: enable test pulse
                                  # bit2: test-polarity 0: negativ 1:positiv
                                  # bit 3: enable test_trigger
#trb_i2c w 0x3800 0x08 0x21 0x0d  # bit3: must be 1, bit 2: nxyter-polarity,
                                  # bit 0-1: test puls channels: 0: 0,4,
                                  # 1:1,5, 2:2,6, 3:3,7

# Threshold setting
#trb_i2c w 0x3800 0x08 18 0x80

# Setup Trigger Generator
trbcmd w 0x3800 0x8141  200    # 500 * 10ns = 5mus Period
trbcmd w 0x3800 0x8142  1      # one Trigger per cycle
trbcmd w 0x3800 0x8143  16     # 200ns trigger length, disable it
trbcmd w 0x3800 0x8144  0      # reset before trigger


# nx_ts_reset_start
trbcmd w 0x3800 0x8102 0x01

# reset counters, flush FIFO
echo "clear data fifo"
trbcmd rm 0x3800 0x8600 4000 1 > /dev/null

# Set readout Mode
trbcmd w 0x3800 0x8180 0x00   # normal mode
trbcmd w 0x3800 0x8182 100    # window width = 100 * 4ns

# Decoder Settings
trbcmd w 0x3800 0x8120 0       # reset all counters

# Enable nxyter
trbcmd w 0x3800 0x8103 0
