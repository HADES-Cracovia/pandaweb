#!/bin/bash

echo "Loading hub configuration"

#CTS sees only one peripheral FPGA (hub), SFP1 only for slow-control
  trbcmd w 0x8000 0xc0 0xffe1
  trbcmd w 0x8000 0xc1 0xffe1
  trbcmd w 0x8000 0xc3 0xfff1

#Timeouts
  trbcmd w 0xfffe 0xc5 0x40ff

#Trb3 for nxyter
  trbcmd w 0x8900 0xc0 0xfff1
  trbcmd w 0x8900 0xc1 0xfff1
  trbcmd w 0x8900 0xc3 0xfff5
  
#Gbe configuration
echo "Load GbE configuration"
../../../tools/loadregisterdb.pl gbe/register_configgbe.db
../../../tools/loadregisterdb.pl gbe/register_configgbe_ip.db



