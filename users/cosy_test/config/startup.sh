#!/bin/bash

echo "Using Daqopserver $DAQOPSERVER."

echo "Run Reset"
trbcmd reset


#Network configuration
./dhcp.sh
./hubconfig.sh

#Front-end configuration
./TrbStart.sh
./nxyter.sh
./cts.sh