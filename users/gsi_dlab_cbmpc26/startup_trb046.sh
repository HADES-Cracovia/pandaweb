# misc

setxkbmap -option ctrl:nocaps
xset -b 


##### TRBNET #####
# set the TRBNet addresses of the Endpoints
trbcmd s 0xb000000390381d28 0 0x0200
trbcmd s 0xa300000390381328 1 0x0201
trbcmd s 0x4800000390381628 2 0x0202
trbcmd s 0x1700000390382028 3 0x0203
trbcmd s 0xdc00000390380c28 5 0x8000

##### Ethernet and UDP #######
trbcmd w 0x8000 0x8300 0x8000          # SubeventId	     
trbcmd w 0x8000 0x8301 0x00020001      # SubEventDecoding	     
trbcmd w 0x8000 0x8302 0x00030062      # Queue decoding	     
trbcmd w 0x8000 0x8303 0xea60	       # max packet size	     
trbcmd w 0x8000 0x8304 0x2260	       # max frame size	     
trbcmd w 0x8000 0x8305 0x1	       # use GbE		     
trbcmd w 0x8000 0x8306 0x0	       # use TRBnet to send data
trbcmd w 0x8000 0x8307 0x0	       # Multi event queue size 
trbcmd w 0x8000 0x8308 0xffffff	       # Trigger counter	     
trbcmd w 0x8000 0x830b 0x7	       # ??		     
trbcmd w 0x8000 0x830d 0x0	       # enable readout bit     

#mac address of the EB
# cbmpc026_eth0: 90:f6:52:03:8f:c4
trbcmd w 0x8000 0x8100 0x52038fc4 # lower 4 bytes
trbcmd w 0x8000 0x8101 0x90f6 #upper byte


# destination port and source IP and so on
trbcmd w 0x8000 0x8102 0xc0a80001     # destination IP-address: 192.168.0.1 
trbcmd w 0x8000 0x8103 0xc350         # destination port		  
trbcmd w 0x8000 0x8104 0xdead8001     # source MAC-address		  
trbcmd w 0x8000 0x8105 0x0230         # source MAC: upper bytes		  
trbcmd w 0x8000 0x8106 0xc0a80072     # source IP			  
trbcmd w 0x8000 0x8107 0xc350	      # source Port			  
trbcmd w 0x8000 0x8108 0x0578         # MTU                                 


#####  TDC  #######
# 0xfe48 is the broadcast address of TDC-endpoints in the system
trbcmd w 0xfe48 0xc800 0x00000001 ## logic analyser control register
trbcmd w 0xfe48 0xc801 0x020f0205 ## trigger window enable & trigger window width
trbcmd w 0xfe48 0xc802 0x00000000 ## channel 01-31 enable
trbcmd w 0xfe48 0xc803 0x00000000 ## channel 32-63 enable
#trbcmd w 0xfe48 0xc8c4 0x00000080 ## enable number of words

trbcmd w 0x0200 0xc802 0x00000000 ## channel 01-4  enable
#trbcmd w 0x0200 0xc803 0xffffffff ## channel 32-63 enable

trbcmd w 0x8000 0xa137 0xfffff  #set CTS pulser to 100Hz
#trbcmd setbit 0x8000 0xa101 0x2 #enable pulser channel 0

##### to disable/enable specific peripheral FPGAs ####
# trbcmd w 0x8000 0xc0 0xf1
# trbcmd w 0x8000 0xc1 0xf1
# trbcmd w 0x8000 0xc3 0xf1
