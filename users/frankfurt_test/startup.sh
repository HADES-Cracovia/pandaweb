#!/bin/bash

echo "reset"
trbcmd reset

echo "addresses"
trbcmd s  0x5f000002e2f93b28  0x05 0x8000
trbcmd s  0xda000002e2e34f28  0x00 0xf000
trbcmd s  0xf9000002e3039928  0x01 0xf001
trbcmd s  0x91000002e2cd5228  0x02 0xf002
trbcmd s  0x48000002e2e36028  0x03 0xf003


echo "Hubs"
trbcmd w 0xfffe 0xc5 0x50ff

../../tools/loadregisterdb.pl register_configgbe.db
../../tools/loadregisterdb.pl register_configgbe_ip.db


echo "cts"
trbcmd w 0x8000 0xa137  1000000


echo "tdc" 
trbcmd w 0xfe48 0xc801 0x000f0000
trbcmd w 0x8000 0xc801 0x000f0000


