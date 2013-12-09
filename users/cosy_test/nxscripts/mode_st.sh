#!/bin/bash

[ -z $1 ] && addr=0xfe49 || addr=$1

# cfg reg
# TP TT
trbcmd clearbit $addr $(( 0x8200 + 32 )) 0x01
trbcmd clearbit $addr $(( 0x8200 + 32 )) 0x08

trbcmd w $addr 0x8218 0

trbcmd w $addr 0x8160 0
