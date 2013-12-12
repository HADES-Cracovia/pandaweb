#!/bin/bash

[ -z $1 ] && addr=0xfe49 || addr=$1

# nx settings

nxi2c $addr 0x0008 16 160
nxi2c $addr 0x0008 17 255
nxi2c $addr 0x0008 18 35
nxi2c $addr 0x0008 19 30
nxi2c $addr 0x0008 20 95
nxi2c $addr 0x0008 21 87
nxi2c $addr 0x0008 22 100
nxi2c $addr 0x0008 23 137
nxi2c $addr 0x0008 24 255
nxi2c $addr 0x0008 25 69
nxi2c $addr 0x0008 26 15
nxi2c $addr 0x0008 27 54
nxi2c $addr 0x0008 28 92
nxi2c $addr 0x0008 29 69
