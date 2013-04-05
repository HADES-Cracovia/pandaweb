
# set addresses
cd ~/trb3



~/bin/generate_serial_table.pl 15


trbcmd s 0x2b00000270d5b328 0x2 0x2
trbcmd s 0x2b00000270d5b328 0x1 0x3

#trbcmd s 0xec000003a426cd28 0x1 0x100 # cbm rich

./configure_trb3.sh # central hub configuration to send data via GbE

# setup tdcs on TRB3
#trbcmd w 0xfe45 0xc0 0x00000001 ## logic analyser control register
#trbcmd w 0xfe45 0xc1 0x000f0005 ## trigger window enable & trigger window width
#trbcmd w 0xfe45 0xc2 0x00000007 ## channel 01-31 enable
#trbcmd w 0xfe45 0xc3 0x00000000 ## channel 32-63 enable


#CTS
#trbcmd loadbit 0x003 0xA0C1 0x0000000F 0x00000004
#trbcmd setbit 0x0003 0xA0C2 0x01000000

#trbcmd w 0x0003 0xA0f1 0x20       #Events per EB
#trbcmd w 0x0003 0xA0f0 0x0001   #15 - 0 EB enable , 
                                #31 - 16 downscale of RPC/TOF TDC trailers and headers

# pulser to 5 Hz
trbcmd w 0x3 0xa0e3 0x1ffffff

# PT1 on
#trbcmd w 0x0003 0xa0c3 0x10000000
#trbcmd w 0x0003 0xa0c4 0x0
#trbcmd w 0x0003 0xa0c5 0x3ff
#trbcmd w 0x0003 0xa0c7 0x800
