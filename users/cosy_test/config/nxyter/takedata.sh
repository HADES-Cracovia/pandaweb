#!/bin/sh

trbcmd   w 0x3800 0x8140 0x01

#trbcmd rm 0x3800 0x8600 2000 1 | grep -v '^H:' | head -n -2 | awk '{printf "%s  %s\n", $1, $2}'
trbcmd rm 0x3800 0x8600 2000 1 
