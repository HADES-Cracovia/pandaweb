#!/bin/bash

echo "================================"
echo "++ Using Daqopserver $DAQOPSERVER."

echo "++ Run Reset"
trbcmd reset

#Network configuration
echo "++ DHCP"
./dhcp.sh
echo "++ HUB"
./hubconfig.sh

#Front-end configuration
echo "++ TRB"
./trbstart.sh
echo "++ nXYTER"
./nxyter.sh
echo "++ CTS"
./cts.sh
echo "++ Scalers"
./scalers.sh

echo "================================"
trbcmd i 0xffff
echo "================================"

echo "done, hit Enter to exit"
