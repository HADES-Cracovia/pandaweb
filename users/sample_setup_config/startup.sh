export DAQOPSERVER=kp1pc105:21
export TRB3_SERVER=trb021

#merge_serial_address.pl ~hadaq/trb3/base/serials_trb3.db ~hadaq/trb3/base/addresses_trb3.db

##################################################
## System Reset
##################################################
echo "reset"
trbcmd reset

echo "addresses"
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

#########################################
# ## set addresses for trb30
# trbcmd s 0x3700000337dfa228 5 0x8001
# trbcmd s 0xd000000337e5b528 0 0xc005
# trbcmd s 0x0100000337e02328 1 0xc006
# trbcmd s 0xca00000337e00f28 2 0xc007
# trbcmd s 0xa100000337dfab28 3 0xc008
#
# # set addresses for trb35
# trbcmd s 0x920000039053d928 5 0x8000
# trbcmd s 0x7100000390255228 0 0xc001
# trbcmd s 0x8c0000039025fa28 1 0xc002
# trbcmd s 0xb00000039053e328 2 0x8002
# trbcmd s 0x790000039053dc28 3 0xc004
#
# trb108
# trbcmd s 0xef000004fa0e3d28 5 0x8002
# trbcmd s 0x3d000004fa143328 0 0xc009
# trbcmd s 0xa3000004fa147628 1 0xc00a
# trbcmd s 0x50000004fa0dff28 2 0xc00b
# trbcmd s 0xd6000004f9ecae28 3 0xc00c
#########################################

echo "GbE settings"
../../tools/loadregisterdb.pl register_configgbe.db
../../tools/loadregisterdb.pl register_configgbe_ip.db

echo "TDC settings"
../../tools/loadregisterdb.pl register_configtdc.db


# Reset trigger logic
trbcmd w 0xffff 0x20 0x33

# timeouts
trbcmd w 0xfffe 0xc5 0x800050ff

# sample trigger logic settings - trigger on TDC 0xc001 channel 1
trbcmd setbit 0xc001 0xcf00 0x1     #direct TDC input to CTS
trbcmd setbit 0x8000 0xa14d 0x10000 #select F5_COMM input

trbcmd w 0x8000 0xa156 1 # important CTS setting: turns of wating for data in external trigger module
