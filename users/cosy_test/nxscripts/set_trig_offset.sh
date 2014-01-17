#!/bin/bash

[ -z $1 ] && val=50 || val=$1
val=0xfe49

trbcmd w $addr 0x8401 $val
