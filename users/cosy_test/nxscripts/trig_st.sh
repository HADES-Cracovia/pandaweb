#!/bin/bash

[ -z $1 ] && addr=0xfe49 || addr=$1

trbcmd w $addr 0x8400 0x0c

