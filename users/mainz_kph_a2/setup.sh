#!/bin/sh
# PATH should already be marked as exported...
PATH=${HOME}/trbsoft/bin:${PATH}
PATH=${HOME}/trbsoft/daqdata/bin:${PATH}
PATH=${HOME}/trbsoft/trbnettools/bin:${PATH}
export TRB3_SERVER=trb019
export DAQOPSERVER=localhost:0

pgrep  dnsmasq > /dev/null
if [[ $? != 0 ]]; then
    echo "No DHCP server found, skipping setup (but exports done)."
		return
fi

pgrep trbnetd > /dev/null
if [[ $? = 0 ]]; then
    echo "trbnetd already running, skipping setup (but exports done)."
    return
fi
${HOME}/trbsoft/trbnettools/binlocal/trbnetd


##### TRBNET #####
# set the TRBNet addresses of the Endpoints
trbcmd s 0x9100000337edaa28 0 0x0200
trbcmd s 0x1900000337dff228 1 0x0201
trbcmd s 0xf700000337df5428 2 0x0202
trbcmd s 0xe300000337def328 3 0x0203
trbcmd s 0xe100000337dff928 5 0x8000

##### Ethernet and UDP #######
trbcmd w 0x8000 0x8300 0x8000
trbcmd w 0x8000 0x8301 0x00020001
trbcmd w 0x8000 0x8302 0x00030062
trbcmd w 0x8000 0x8303 0xea60
trbcmd w 0x8000 0x8304 0x2260
trbcmd w 0x8000 0x8305 0x1
trbcmd w 0x8000 0x8306 0x0
trbcmd w 0x8000 0x8307 0x0
trbcmd w 0x8000 0x8308 0xffffff
trbcmd w 0x8000 0x830b 0x7
trbcmd w 0x8000 0x830d 0x0

#mac address of the EB
# 14:fe:b5:ec:10:9a (normandy)
#trbcmd w 0x8000 0x8100 0xb5ec109a # lower 4 bytes
#trbcmd w 0x8000 0x8101 0x14fe # upper byte
# 00:19:b9:0a:ad:e2 (a2trb)
trbcmd w 0x8000 0x8100 0xb90aade2 # lower 4 bytes
trbcmd w 0x8000 0x8101 0x0019 # upper byte

# destination port and source IP and so on
trbcmd w 0x8000 0x8102 0xc0a80101
trbcmd w 0x8000 0x8103 0xc350
trbcmd w 0x8000 0x8104 0xdead8001
trbcmd w 0x8000 0x8105 0x0230
trbcmd w 0x8000 0x8106 0xc0a80072
trbcmd w 0x8000 0x8107 0xc350
trbcmd w 0x8000 0x8108 0x0578


#####  TDC  #######
trbcmd w 0x0200 0xc800 0x00000001 ## logic analyser control register
trbcmd w 0x0200 0xc801 0x000f0005 ## trigger window enable & trigger window width
trbcmd w 0x0200 0xc802 0x00000000 ## channel 01-31 enable
trbcmd w 0x0200 0xc803 0x00000000 ## channel 32-63 enable
trbcmd w 0x0200 0xc804 0x00000080 ## no read out limit


#trbcmd w 0x0200 0xc2 0x0000ffff ## channel 01-31 enable

trbcmd w 0x8000 0xc800 0x00000001      # logic analyser control register
trbcmd w 0x8000 0xc801 0x000f0005      # trigger window enable & trigger window width (off if MSB not set)
trbcmd w 0x8000 0xc802 0x00000002      # channel 32- 1 enable (0 is reference time and always on)
trbcmd w 0x8000 0xc803 0x00000000      # channel 64-33 enable
trbcmd w 0x8000 0xc804 0x00000080 ## no read out limit



#####  CTS  #######
trbcmd w 0x8000 0xa137 0xfffff  #set CTS pulser to 100Hz
#trbcmd setbit 0x8000 0xa101 0x2 #enable pulser channel 0
trbcmd setbit 0x8000 0xa101 0x1 # enable external trigger module



echo "Successfully setup TRB network"
