#!/bin/bash

[ -z $1 ] && addr=0xfe49 || addr=$1

trbcmd clearbit $addr 0x8250 0x01

sleep 1

trbcmd setbit $addr 0x8250 0x01
