#!/bin/bash

echo "Doing CTS configuration"

trbcmd w 0x8000 0xa140 0x000f4240 # pulser freq 100 Hz
#trbcmd w 0x8000 0xa140 0x05f5e0ff # pulser freq 1 Hz
trbcmd w 0x8000 0xa141 0x05f5e100  #periodic pulser 1 at 1 Hz for 0xE trigger type

trbcmd loadbit 0x8000 0xa148 0x0f00 0x0e00 # setting trigger type E for second pulser
#trbcmd setbit  0x8000 0xa101 0x6 # turn on periodic pulser 1 and 0
trbcmd setbit  0x8000 0xa101 0x2 # turn on periodic pulser 0
trbcmd setbit  0x8000 0xa101 0x4 # turn on periodic pulser 1

#trbcmd loadbit 0x8000 0xa13d 0x7f 0xa # setting multiplexer input
trbcmd loadbit 0x8000 0xa13d 0x7f 0xc # nim 1

trbcmd loadbit 0x8000 0xa13e 0x7f 0xb # setting multiplexer input
trbcmd loadbit 0x8000 0xa129 0x100 0x100 # setting multiplexer input invert



trbcmd w 0x8000 0xc801 0x000f000f   #for TDC inside CTS (not used): set trigger window

