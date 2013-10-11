#!/bin/bash

[ -n $1 ] && addr=0x3800 || addr=$1

# TP
trb_i2c w $addr 0x0008 32 0x01
trb_i2c w $addr 0x0008 33 15
