#!/bin/bash

#Disable second TRB3 & unused ADC FPGA
#trbcmd w 0xc000 0xc0 0x0ff9
#trbcmd w 0xc000 0xc1 0x0ff9
#trbcmd w 0xc000 0xc3 0x0ff9


#cd ../../tools/
./adc.pl 0xf4cc init
#cd ../users/frankfurt_test


trbcmd w 0xf4cc 0xa010 24          #Buffer depth
trbcmd w 0xf4cc 0xa011 8           #Samples after trigger
trbcmd w 0xf4cc 0xa012 2           #Process blocks
trbcmd w 0xf4cc 0xa013 40          #Trigger offset
trbcmd w 0xf4cc 0xa014 40          #Readout offset
trbcmd w 0xf4cc 0xa015 0           #Downsampling
trbcmd w 0xf4cc 0xa016 8           #Baseline
trbcmd w 0xf4cc 0xa017 1           #Trigger Enable

trbcmd w 0xf4cc 0xa020 0           #Sum values
trbcmd w 0xf4cc 0xa021 0           #Sum values
trbcmd w 0xf4cc 0xa022 0           #Sum values
trbcmd w 0xf4cc 0xa023 0           #Sum values
trbcmd w 0xf4cc 0xa024 15          #word count
trbcmd w 0xf4cc 0xa025 7           #word count
trbcmd w 0xf4cc 0xa026 0           #word count
trbcmd w 0xf4cc 0xa027 0           #word count

trbcmd w 0xf4cc 0xa000 0x100       #Reset Baseline

#trbcmd setbit  0x8000 0xa14d 0x00040000              #External trigger selector
#trbcmd setbit  0x8000 0xa101 0x00000400              #External trigger on

#trbcmd w       0x8000 0xa150 0x05f5e0ff              #1 Hz pulser
#trbcmd loadbit 0x8000 0xa158 0x000000f0 0x000000e0   #Pulser 0xe type
#trbcmd setbit  0x8000 0xa101 0x00000002              #Pulser on


