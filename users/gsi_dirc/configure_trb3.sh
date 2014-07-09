# CTS Board 0x8000 trb060
trbcmd w 0x8000 0x8300 0x8000       # SubeventId
trbcmd w 0x8000 0x8301 0x00020001   # SubEventDecoding
trbcmd w 0x8000 0x8302 0x00030062   # Queue decoding
trbcmd w 0x8000 0x8303 0xea60       # max packet size
trbcmd w 0x8000 0x8304 0x0578       # max frame size
trbcmd w 0x8000 0x8305 0x1          # use GbE
trbcmd w 0x8000 0x8306 0x0          # use TRBnet to send data
trbcmd w 0x8000 0x8307 0x0          # Multi event queue size
trbcmd w 0x8000 0x8308 0xffffff     # Trigger counter
trbcmd w 0x8000 0x830b 0x7          # ??
trbcmd w 0x8000 0x830d 0x1          # enable readout bit

#mac address of the EB
#kp1pc105 00:1b:21:43:97:ea
#dircdaq002 d4:ae:52:ba:16:a6
trbcmd w 0x8000 0x8100 0x52ba16a6   # lower 4 bytes 
trbcmd w 0x8000 0x8101 0xd4ae       # upper two bytes

trbcmd w 0x8000 0x8102 0xc0a80001   # destination IP-address: 192.168.0.2
trbcmd w 0x8000 0x8103 0xc350       # destination port 50000
trbcmd w 0x8000 0x8104 0xdead0110   # source MAC-address
trbcmd w 0x8000 0x8105 0x001b       # source MAC: upper bytes
trbcmd w 0x8000 0x8106 0xc0a80138   # source IP trb056
trbcmd w 0x8000 0x8107 0xc353       # source Port
trbcmd w 0x8000 0x8108 0x578        # MTU



## Slave 1 0x8001 trb061
#trbcmd w 0x8001 0x8300 0x8001       # SubeventId
#trbcmd w 0x8001 0x8301 0x00020001   # SubEventDecoding
#trbcmd w 0x8001 0x8302 0x00030062   # Queue decoding
#trbcmd w 0x8001 0x8303 0xea60       # max packet size
#trbcmd w 0x8001 0x8304 0x0578       # max frame size
#trbcmd w 0x8001 0x8305 0x1          # use GbE
#trbcmd w 0x8001 0x8306 0x0          # use TRBnet to send data
#trbcmd w 0x8001 0x8307 0x0          # Multi event queue size
#trbcmd w 0x8001 0x8308 0xffffff     # Trigger counter
#trbcmd w 0x8001 0x830b 0x7          # ??
#trbcmd w 0x8001 0x830d 0x1          # enable readout bit

##mac address of the EB
##kp1pc105 00:1b:21:43:97:ea
#trbcmd w 0x8001 0x8100 0x214397ea   # lower 4 bytes 
#trbcmd w 0x8001 0x8101 0x001b       # upper two bytes
#
#trbcmd w 0x8001 0x8102 0xc0a80001   # destination IP-address: 192.168.0.1
#trbcmd w 0x8001 0x8103 0xc352       # destination port 50002
#                                    # port 50001 is for debug messages from GbE
#trbcmd w 0x8001 0x8104 0xdead0110   # source MAC-address
#trbcmd w 0x8001 0x8105 0x001b       # source MAC: upper bytes
#trbcmd w 0x8001 0x8106 0xc0a8013d   # source IP trb061
#trbcmd w 0x8001 0x8107 0xc353       # source Port
#trbcmd w 0x8001 0x8108 0x578        # MTU
#

## Slave 2 0x8002 trb062
#trbcmd w 0x8002 0x8300 0x8002       # SubeventId
#trbcmd w 0x8002 0x8301 0x00020001   # SubEventDecoding
#trbcmd w 0x8002 0x8302 0x00030062   # Queue decoding
#trbcmd w 0x8002 0x8303 0xea60       # max packet size
#trbcmd w 0x8002 0x8304 0x0578       # max frame size
#trbcmd w 0x8002 0x8305 0x1          # use GbE
#trbcmd w 0x8002 0x8306 0x0          # use TRBnet to send data
#trbcmd w 0x8002 0x8307 0x0          # Multi event queue size
#trbcmd w 0x8002 0x8308 0xffffff     # Trigger counter
#trbcmd w 0x8002 0x830b 0x7          # ??
#trbcmd w 0x8002 0x830d 0x1          # enable readout bit

##mac address of the EB
##kp1pc105 00:1b:21:43:97:ea
#trbcmd w 0x8002 0x8100 0x214397ea   # lower 4 bytes 
#trbcmd w 0x8002 0x8101 0x001b       # upper two bytes
#
#trbcmd w 0x8002 0x8102 0xc0a80001   # destination IP-address: 192.168.0.1
#trbcmd w 0x8002 0x8103 0xc353       # destination port 50003
#                                    # port 50001 is for debug messages from GbE
#trbcmd w 0x8002 0x8104 0xdead0110   # source MAC-address
#trbcmd w 0x8002 0x8105 0x001b       # source MAC: upper bytes
#trbcmd w 0x8002 0x8106 0xc0a8013e   # source IP trb062
#trbcmd w 0x8002 0x8107 0xc353       # source Port
#trbcmd w 0x8002 0x8108 0x578        # MTU
#

## Slave 3 0x8003 trb063
#trbcmd w 0x8003 0x8300 0x8003       # SubeventId
#trbcmd w 0x8003 0x8301 0x00020001   # SubEventDecoding
#trbcmd w 0x8003 0x8302 0x00030062   # Queue decoding
#trbcmd w 0x8003 0x8303 0xea60       # max packet size
#trbcmd w 0x8003 0x8304 0x0578       # max frame size
#trbcmd w 0x8003 0x8305 0x1          # use GbE
#trbcmd w 0x8003 0x8306 0x0          # use TRBnet to send data
#trbcmd w 0x8003 0x8307 0x0          # Multi event queue size
#trbcmd w 0x8003 0x8308 0xffffff     # Trigger counter
#trbcmd w 0x8003 0x830b 0x7          # ??
#trbcmd w 0x8003 0x830d 0x1          # enable readout bit

##mac address of the EB
##kp1pc105 00:1b:21:43:97:ea
#trbcmd w 0x8003 0x8100 0x214397ea   # lower 4 bytes 
#trbcmd w 0x8003 0x8101 0x001b       # upper two bytes
#
#trbcmd w 0x8003 0x8102 0xc0a80001   # destination IP-address: 192.168.0.1
#trbcmd w 0x8003 0x8103 0xc354       # destination port 50004
#                                    # port 50001 is for debug messages from GbE
#trbcmd w 0x8003 0x8104 0xdead0110   # source MAC-address
#trbcmd w 0x8003 0x8105 0x001b       # source MAC: upper bytes
#trbcmd w 0x8003 0x8106 0xc0a8013f   # source IP trb063
#trbcmd w 0x8003 0x8107 0xc353       # source Port
#trbcmd w 0x8003 0x8108 0x578        # MTU
