#!/bin/bash

echo "reset"
trbcmd reset

echo "addresses"
trbcmd s  0x5f000002e2f93b28  0x05 0x8200
trbcmd s  0xda000002e2e34f28  0x00 0xf000
trbcmd s  0xf9000002e3039928  0x01 0xf001
trbcmd s  0x91000002e2cd5228  0x02 0xf002
trbcmd s  0x48000002e2e36028  0x03 0xf003

trbcmd s  0x650000031321c728  0x05 0x8100
trbcmd s  0x04000003133e3728  0x00 0xf100
trbcmd s  0x8e0000031321c228  0x01 0xf101
trbcmd s  0xe1000003133e4b28  0x02 0xf102
trbcmd s  0xef000003133e3228  0x03 0xf103

#90
trbcmd s  0x2f0000046f397d28  0x05 0xc000
trbcmd s  0x810000046f398928  0x01 0x5001
trbcmd s  0xa50000046f398628  0x00 0x5000
trbcmd s  0x220000046f399228  0x02 0x5002
trbcmd s  0x290000046f075428  0x03 0x5003

#82
trbcmd s  0xa300000313233628  0x05 0x8820
trbcmd s  0x8d000003133e5a28  0x00 0x5820
trbcmd s  0x9400000313233728  0x01 0x5821
trbcmd s  0x4e000003131c0328  0x02 0x5822
trbcmd s  0xa0000003133cae28  0x03 0x5823

#148
trbcmd s  0x250000070ef43028  0x05 0xc148
trbcmd s  0xed0000070ee63128  0x01 0x0481
trbcmd s  0x4e0000070ef49128  0x00 0x0480
trbcmd s  0x790000070ef49028  0x02 0x0482
trbcmd s  0x270000070ef42328  0x03 0x0483

#2
trbcmd s 0x08000002e2e22b28  0x05  0xc002
trbcmd s 0xa6000002e2e2df28  0x00 0x8200
trbcmd s 0x51000002e2e22828  0x01 0x0201
trbcmd s 0x72000002e2eb4628  0x02 0x0202
trbcmd s 0xb0000002e311b928  0x03 0x0203

#Dirich
trbcmd s  0x58000007125dbc28  0x01 0xf3d2

#ADC AddOn
trbcmd s  0x7a0000050df02428  0x01 0xf4cc

echo "Hubs"
trbcmd w 0xfffe 0xc5 0x50ff
trbcmd w 0xfc00 0xc5 0x50ff

#trbcmd w 0x8000 0xc0 0x0fef
#trbcmd w 0x8000 0xc1 0x0fef

../../tools/loadregisterdb.pl register_configgbe.db
../../tools/loadregisterdb.pl register_configgbe_ip.db


echo "cts"
trbcmd w 0xc002 0xa156  100000
trbcmd w 0xc000 0xa156  1000000
trbcmd w 0xc000 0xa157  10000
trbcmd w 0xc148 0xa150  1000000


echo "tdc" 
trbcmd w 0xfe48 0xc801 0x000f0000
trbcmd w 0xfe4e 0xc801 0x000f0000
#trbcmd w 0x8000 0xc801 0x000f0000

trbcmd w 0xfe48 0xc804 0x00000040
trbcmd w 0xfe4e 0xc804 0x00000040
#trbcmd w 0x8000 0xc804 0x00000010


