#!/bin/bash

[ -n $1 ] && addr=0x3800 || addr=$1

trbcmd w $addr 0x8180 1
trbcmd w $addr 0x8181 0
trbcmd w $addr 0x8182 1000
trbcmd w $addr 0x8183 0
trbcmd w $addr 0x8183 1000

#trbcmd w $addr 0x8140 1
#trbcmd w $addr 0x8144 1

trbcmd w $addr 0x8160 0
trbcmd w $addr 0x8161 1
#trbcmd w $addr 0x8144 1

trbcmd w $addr 0x8102 1
trbcmd w $addr 0x8103 0
