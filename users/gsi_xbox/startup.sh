#!/bin/bash

echo "reset"
trbcmd reset

echo "addresses"
trbcmd s 0x1c0000039018f128  0x05 0x8000
trbcmd s 0x7d000003901c6b28  0x00 0x50f0
trbcmd s 0x630000039018ee28  0x01 0x50f1
trbcmd s 0xf000000390074a28  0x02 0x50f2
trbcmd s 0x1d00000390077a28  0x03 0x50f3


echo "Hubs"
trbcmd w 0xfffe 0xc5 0x50ff

../../tools/loadregisterdb.pl register_configgbe.db
../../tools/loadregisterdb.pl register_configgbe_ip.db


#echo "cts"
trbcmd w 0x8000 0xa137  1000000


#echo "tdc" 
trbcmd w 0xfe4e 0xc801 0x000f0000
trbcmd w 0x8000 0xc801 0x000f0000

trbcmd w 0xfe4e 0xc804 0x00000040
trbcmd w 0x8000 0xc804 0x00000010

echo "Loading thresholds"
../../tools/dac_program.pl DAC_nino.db
