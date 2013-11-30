#!/bin/bash

echo "Loading hub configuration"

#CTS sees only one peripheral FPGA (hub), SFP1 only for slow-control
  # 0x8000
  # 1111 1111 111x xxxx
  #                   |- fpga 0 - hub
  #                  |- fpga 1 - 32bit addon / TDC
  #                |- fpga 3 - padiwa
  #              |- Pexor!

  trbcmd w 0x8000 0xc0 0xffe1	#
  trbcmd w 0x8000 0xc1 0xffe1	#
  trbcmd w 0x8000 0xc3 0xfffb

  # 0x8001
  # 1111 1111 111x xxxx
  #                   |- sfp 0 - pion tracker
  #                  |- sfp 1 - hub/0x8081

  trbcmd w 0x8001 0xc0 0xffff
  trbcmd w 0x8001 0xc1 0xffff
  trbcmd w 0x8001 0xc3 0xffff

#Timeouts
  trbcmd w 0xfffe 0xc5 0x40ff

#Trb3 for nxyter
  # 0x8900
  # 1111 1111 1111 1111
  #                   |- fpga 0 - nxyter
  #                  |- fpga 1 - nxyter
  #                 |- fpga 2 - nxyter
  #                |- fpga 3 - nxyter

  trbcmd w 0x8900 0xc0 0xffff
  trbcmd w 0x8900 0xc1 0xffff
  trbcmd w 0x8900 0xc3 0xffff

# my
#  trbcmd w 0x8001 0xc0 0xfff5
#  trbcmd w 0x8001 0xc1 0xfff5
#  trbcmd w 0x8001 0xc3 0xfff5

  trbcmd w 0x8801 0xc0 0xffff
  trbcmd w 0x8801 0xc1 0xffff
  trbcmd w 0x8801 0xc3 0xffff

# /my

#Gbe configuration
echo "Load GbE configuration"
../../../tools/loadregisterdb.pl gbe/register_configgbe.db
../../../tools/loadregisterdb.pl gbe/register_configgbe_ip.db

