##################################################
## System Reset
##################################################
echo "reset"
trbcmd reset

echo "addresses"
# merge_serial_address.pl ~hadaq/trb3/base/serials_trb3.db ~hadaq/trb3/base/addresses_trb3.db
# set addresses for trb21
trbcmd s 0x3d000002e2da7328 5 0x8000
trbcmd s 0x5d000002e3194128 0 0xc001
trbcmd s 0x2c000002e31f7128 1 0xc002
trbcmd s 0x57000002e2f38d28 3 0xc004
trbcmd s 0x6b000002e2e49028 2 0x8100 #hub

# trb107
trbcmd s 0x5d000004f9e50128 5 0x8001
trbcmd s 0x26000004fa018528 0 0xc005
trbcmd s 0x84000004fa011b28 1 0xc006
trbcmd s 0xa4000004fa244428 2 0xc007
trbcmd s 0x8c000004f9fae428 3 0xc008

# cbmtof
trbcmd s 0xb80000050da05e28 0 0xc010

echo "GbE settings"
../../tools/loadregisterdb.pl register_configgbe.db
../../tools/loadregisterdb.pl register_configgbe_ip.db

echo "TDC settings"
../../tools/loadregisterdb.pl register_configtdc.db

# Reset trigger logic
trbcmd w 0xffff 0x20 0x33

# timeouts
trbcmd w 0xfffe 0xc5 0x800050ff

trbcmd w 0x8000 0xa156 1 # important CTS setting: turns off wating for data in external trigger module
