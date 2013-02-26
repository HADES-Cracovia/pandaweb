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
trbcmd w 0x8000 0x8100 0x214397ea   # lower 4 bytes 
trbcmd w 0x8000 0x8101 0x001b       # upper two bytes

trbcmd w 0x8000 0x8102 0xc0a80101   # destination IP-address: 192.168.1.1
trbcmd w 0x8000 0x8103 0xc352       # destination port
trbcmd w 0x8000 0x8104 0xdead0110   # source MAC-address
trbcmd w 0x8000 0x8105 0x001b       # source MAC: upper bytes
trbcmd w 0x8000 0x8106 0xc0a8011e   # source IP
trbcmd w 0x8000 0x8107 0xc353       # source Port
trbcmd w 0x8000 0x8108 0x578        # MTU
