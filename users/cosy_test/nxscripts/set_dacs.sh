#!/bin/bash

[ -n $1 ] && addr=0x3800 || addr=$1

# nx settings

trb_i2c w $addr 0x0008 16 160
trb_i2c w $addr 0x0008 17 255
trb_i2c w $addr 0x0008 18 35
trb_i2c w $addr 0x0008 19 30
trb_i2c w $addr 0x0008 20 95
trb_i2c w $addr 0x0008 21 87
trb_i2c w $addr 0x0008 22 100
trb_i2c w $addr 0x0008 23 137
trb_i2c w $addr 0x0008 24 255
trb_i2c w $addr 0x0008 25 69
trb_i2c w $addr 0x0008 26 15
trb_i2c w $addr 0x0008 27 54
trb_i2c w $addr 0x0008 28 92
trb_i2c w $addr 0x0008 29 69
