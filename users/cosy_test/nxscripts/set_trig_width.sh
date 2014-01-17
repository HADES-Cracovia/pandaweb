#!/bin/bash

[ -z $1 ] && val=50 || val=$1
addr=0xfe49

trbcmd w $addr 0x8402 $val
