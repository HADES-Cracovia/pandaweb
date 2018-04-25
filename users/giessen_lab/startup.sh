#!/bin/bash

echo "reset"
trbcmd reset

echo "addresses"
trbcmd s 0xdc00000813262728  0x05 0xc002
trbcmd s 0xd400000812a36228  0x02 0x0200
trbcmd s 0xde00000813263428  0x00 0x0201
trbcmd s 0xf800000813262828  0x01 0x0202
trbcmd s 0x7000000812a3c928  0x03 0x0203

./merge_serial_address.pl /home/hadaq/trbsoft/daqtools/base/serials_dirich.db /home/hadaq/trbsoft/daqtools/users/giessen_lab/db/addresses_dirich.db
./merge_serial_address.pl /home/hadaq/trbsoft/daqtools/base/serials_dirich_concentrator.db /home/hadaq/trbsoft/daqtools/users/giessen_lab/db/addresses_dirich_concentrator.db


echo "Hubs"
trbcmd w 0xfffe 0xc5 0x50ff

../../tools/loadregisterdb.pl register_configgbe.db
../../tools/loadregisterdb.pl register_configgbe_ip.db


echo "cts"
#trbcmd w 0xc002 0xa154  1000000
trbcmd w 0xc002 0xa156  0x0002710


echo "tdc" 
#trbcmd w 0xfe48 0xc801 0x000f0000
#trbcmd w 0xfe48 0xc804 0x00000040


