#!/bin/bash

# MAC Address of the EB
# i.e. 6C:F0:49:02:D7:45
#trbcmd w 0x8000 0x8100 0x4902d745   # Lower 32 bits of EB MAC
#trbcmd w 0x8000 0x8101 0x6cf0       # Bit 15..0: Higher 16 bit of EB MAC,
trbcmd w 0x8000 0x8100 0x0c:2e:81:76 # Lower 32 bits of EB MAC
trbcmd w 0x8000 0x8101 0x00:0e       # Bit 15..0: Higher 16 bit of EB MAC,

# IP Adress and Port of EB: (10.152.8.107:50000)
#trbcmd w 0x8000 0x8102 0x0a98086b   # Destination IP
#trbcmd w 0x8000 0x8103 0xc350       # Bit 15..0: Destination UDP Port
# IP Adress and Port of EB: (10.152.8.107:50000)
trbcmd w 0x8000 0x8102 0xc0a8016b   # Destination IP
trbcmd w 0x8000 0x8103 0xc350       # Bit 15..0: Destination UDP Port

# MAC Adress of Source (trb3)
trbcmd w 0x8000 0x8104 0xdead8001   # Lower 32 bits of Source MAC
trbcmd w 0x8000 0x8105 0x0230       # Bit 15..0: Higher 16 bit of Source MAC

# IP and Port of Source (10.152.8.17:50000)
#trbcmd w 0x8000 0x8106 0x0a980811   # Source IP
trbcmd w 0x8000 0x8102 0xc0a80111   # Destination IP
trbcmd w 0x8000 0x8107 0xc350       # Bit 15..0: Source UDP Port 
trbcmd w 0x8000 0x8108 0x0578       # Bit 15..0: MTU size
