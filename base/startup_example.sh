# example startup file, tailored for trb046

# You *have* to adapt the trbnetaddresses to get the CTS running
# Also the destination MAC address has to be changed if you want to see data

##### TRBNET #####
# set the TRBNet addresses of the Endpoints
#trbcmd s 0xb000000390381d28 0 0x0200
#trbcmd s 0xa300000390381328 1 0x0201
#trbcmd s 0x4800000390381628 2 0x0202
#trbcmd s 0x1700000390382028 3 0x0203
#trbcmd s 0xdc00000390380c28 5 0x8000

# automatic setup of all trbnet addresses
~/daqtools/merge_serial_address.pl ~/daqtools/base/serials_trb3.db ~/daqtools/base/addresses_trb3.db > /dev/null

##### Ethernet and UDP #######
trbcmd w 0x8000 0x8300 0x8000        #Subsystem ID in data files, should be equal to address
trbcmd w 0x8000 0x8301 0x00020001
trbcmd w 0x8000 0x8302 0x00030062
trbcmd w 0x8000 0x8303 0xea60        #Maximum UDP packet size (<62 kB!)
trbcmd w 0x8000 0x8304 0x2260        #Maximum Ethernet frame size
trbcmd w 0x8000 0x8305 0x1           #Enable GbE
trbcmd w 0x8000 0x8306 0x0
trbcmd w 0x8000 0x8307 0x0           #Pack multiple events in one packet to reduce overhead
trbcmd w 0x8000 0x8308 0xffffff
trbcmd w 0x8000 0x830b 0x7
trbcmd w 0x8000 0x830d 0x0

#mac address of the EB
# cbmpc026_eth0: 90:f6:52:03:8f:c4
trbcmd w 0x8000 0x8100 0x52038fc4    # lower 4 bytes of receiver Max
trbcmd w 0x8000 0x8101 0x90f6 #upper byte

# destination port and source IP and so on
trbcmd w 0x8000 0x8102 0xc0a80001 # destination IP 192.168.0.1
trbcmd w 0x8000 0x8103 0xc350     # destination port: 50000
trbcmd w 0x8000 0x8104 0xdead8001 # source IP
trbcmd w 0x8000 0x8105 0x0230     
trbcmd w 0x8000 0x8106 0xc0a80072
trbcmd w 0x8000 0x8107 0xc350     # source port
trbcmd w 0x8000 0x8108 0x0578     #ignore


#####  TDC  #######
# 0xfe48 is the broadcast address of TDC-endpoints in the system
trbcmd w 0xfe48 0xc0 0x00000001 ## logic analyser control register
trbcmd w 0xfe48 0xc1 0x000f0005 ## trigger window enable & trigger window width
trbcmd w 0xfe48 0xc2 0xffffffff ## channel 01-31 enable
trbcmd w 0xfe48 0xc3 0x00000000 ## channel 32-63 enable




trbcmd w 0x8000 0xa137 0xfffff  #set CTS pulser to 100Hz
trbcmd setbit 0x8000 0xa101 0x2 #enable pulser channel 0
