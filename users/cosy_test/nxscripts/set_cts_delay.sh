#!/bin/bash

[ -z $1 ] && ctsd=50 || ctsd=$1
addr=0xfe49

trbcmd w $addr 0x8403 $ctsd
