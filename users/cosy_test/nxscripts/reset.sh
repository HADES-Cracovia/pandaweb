#!/bin/bash

[ -n $1 ] && addr=0xfe49 || addr=$1

trbcmd w $addr 0x8100 1
trbcmd w $addr 0x8101 1
