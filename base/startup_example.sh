#This example start-up script as to be adapted to your setup!
#0x8000 is assumed to be the address of the central board running CTS and GbE


####### TrbNet           #######
################################

# automatic setup of all trbnet addresses
~/daqtools/merge_serial_address.pl ~/daqtools/base/serials_trb3.db ~/daqtools/base/addresses_trb3.db > /dev/null

#If you need to use special addresses, generate your own addresses_trb3.db or state the addresses explicitly as shown below:
#trbcmd s 0xb000000390381d28 0 0x0200




####### Ethernet and UDP #######
################################
#Repeat this block for all boards using GbE

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

trbcmd w 0x8000 0x8100 0x52038fc4    # lower 4 bytes of receiver Mac
trbcmd w 0x8000 0x8101 0x90f6        # upper 2 bytes of receiver Mac
trbcmd w 0x8000 0x8102 0xc0a80001    # destination IP 192.168.0.1
trbcmd w 0x8000 0x8103 0xc350        # destination port: 50000
trbcmd w 0x8000 0x8104 0xdead8001    # source IP
trbcmd w 0x8000 0x8105 0x0230        # Lower 4 bytes of sender Mac
trbcmd w 0x8000 0x8106 0xc0a80072    # Upper 2 byte of sender Mac
trbcmd w 0x8000 0x8107 0xc350        # destination port
trbcmd w 0x8000 0x8108 0x0578        




####### TDC              #######
################################
# Settings for all TRB3-TDC-endpoints in the system
trbcmd w 0xfe48 0xc0 0x00000001      # logic analyser control register
trbcmd w 0xfe48 0xc1 0x000f0005      # trigger window enable & trigger window width (off if MSB not set)
trbcmd w 0xfe48 0xc2 0xffffffff      # channel 32- 1 enable (0 is reference time and always on)
trbcmd w 0xfe48 0xc3 0x00000000      # channel 64-33 enable

#Settings for TDC inside CTS
trbcmd w 0x8000 0xc0 0x00000001      # logic analyser control register
trbcmd w 0x8000 0xc1 0x000f0005      # trigger window enable & trigger window width (off if MSB not set)
trbcmd w 0x8000 0xc2 0x00000000      # channel 32- 1 enable (0 is reference time and always on)
trbcmd w 0x8000 0xc3 0x00000000      # channel 64-33 enable



####### CTS              #######
################################
#A dump of register settings can be obtained from the Web GUI!

trbcmd w 0x8000 0xa137 0xfffff       #set CTS pulser 0 to 100Hz
trbcmd setbit 0x8000 0xa101 0x2      #enable pulser 0
