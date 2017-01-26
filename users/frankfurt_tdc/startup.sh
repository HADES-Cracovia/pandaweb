#!/bin/bash

echo "reset"
trbcmd reset

echo "addresses"
trbcmd s 0x08000002e2e22b28  0x05  0xc002
trbcmd s 0xa6000002e2e2df28  0x00 0x8200
trbcmd s 0x51000002e2e22828  0x01 0x0201
trbcmd s 0x72000002e2eb4628  0x02 0x0202
trbcmd s 0xb0000002e311b928  0x03 0x0203



echo "Hubs"
trbcmd w 0xfffe 0xc5 0x50ff

../../tools/loadregisterdb.pl register_configgbe.db
../../tools/loadregisterdb.pl register_configgbe_ip.db


echo "cts"
trbcmd w 0xc002 0xa154  1000000


echo "tdc" 
#trbcmd w 0xfe48 0xc801 0x000f0000
#trbcmd w 0xfe48 0xc804 0x00000040


