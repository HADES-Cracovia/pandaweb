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
trbcmd s  0x2f0000046f397d28  0x05 0x8000
trbcmd s  0x810000046f398928  0x01 0xf901
trbcmd s  0xa50000046f398628  0x00 0xf900
trbcmd s  0x220000046f399228  0x02 0xf902
trbcmd s  0x290000046f075428  0x03 0xf903


echo "Hubs"
trbcmd w 0xfffe 0xc5 0x50ff
trbcmd w 0xfc00 0xc5 0x50ff

trbcmd w 0x8000 0xc0 0x0fef
trbcmd w 0x8000 0xc1 0x0fef

../../tools/loadregisterdb.pl register_configgbe.db
../../tools/loadregisterdb.pl register_configgbe_ip.db


echo "cts"
trbcmd w 0x8000 0xa150  1000000


echo "tdc" 
trbcmd w 0xfe48 0xc801 0x000f0000
trbcmd w 0xfe4e 0xc801 0x000f0000
trbcmd w 0x8000 0xc801 0x000f0000

trbcmd w 0xfe48 0xc804 0x00000040
trbcmd w 0xfe4e 0xc804 0x00000040
trbcmd w 0x8000 0xc804 0x00000010


