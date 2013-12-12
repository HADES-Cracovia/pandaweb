#!/bin/bash

echo "================================"
echo "++ Using Daqopserver $DAQOPSERVER."

echo "++ Run Reset"

#pkill trbnetd -SIGUSR1;
#TRB3_SERVER=trb3069 ~/trbsoft/trbnettools/binlocal/trbcmd reset;
#pkill trbnetd -SIGUSR2;

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
