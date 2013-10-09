#!/bin/sh

#enable Testmode

trb_i2c w 0x3800 0x08 0x21 0x0d  # bit 3: must be 1,
                                 # bit 2: nxyter-polarity 0: negative
                                 # bit 0-1: test puls channels:
                                 #   0: 0,4, 1:1,5, 2:2,6, 3:3,7

trb_i2c w 0x3800 0x08 0x20 0x01  # bit3: enable test_trigger
                                 # bit2: test-polarity 0: negative
                                 # bit1: test-pulse synchronise
                                 # bit0: enable test pulse
