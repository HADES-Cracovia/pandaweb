#!/bin/bash

[ -n $1 ] && addr=0xfe49 || addr=$1

trbcmd w $addr 0x8180 0
trbcmd w $addr 0x8181 0
trbcmd w $addr 0x8182 250
trbcmd w $addr 0x8183 100

trbcmd w $addr 0x8140 0
#trbcmd w $addr 0x8144 1

trbcmd w $addr 0x8160 0
trbcmd w $addr 0x8161 0
#trbcmd w $addr 0x8144 1

trbcmd w $addr 0x8102 1
trbcmd w $addr 0x8103 0
