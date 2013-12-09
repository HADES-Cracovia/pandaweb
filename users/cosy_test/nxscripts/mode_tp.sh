#!/bin/bash

[ -z $1 ] && addr=0xfe49 || addr=$1

# cfg reg
# TP TT
#nxi2c $addr 32 0x09
#nxi2c $addr 33 0x0f

trbcmd setbit $addr $(( 0x8200 + 32 )) 0x01
trbcmd setbit $addr $(( 0x8200 + 32 )) 0x08

trbcmd w $addr 0x8218 0xff

trbcmd w $addr 0x8160 1
trbcmd w $addr 0x8140 100
