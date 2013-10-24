#!/bin/bash

[ -n $1 ] && addr=0x3800 || addr=$1

# TT
trb_i2c w $addr 0x0008 32 0x08
trb_i2c w $addr 0x0008 33 15
