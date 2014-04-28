#!/bin/bash

[ -z $1 ] && addr=0xfe49 || addr=$1

# TT
trbcmd clearbit $addr $(( 0x8200 + 32 )) 0x01
trbcmd setbit $addr $(( 0x8200 + 32 )) 0x08

trbcmd w $addr 0x8160 1
trbcmd w $addr 0x8162 100

trbcmd w $addr 0x8218 0xff
