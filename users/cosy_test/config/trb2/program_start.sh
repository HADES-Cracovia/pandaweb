#!/bin/bash

echo "Programming FPGAs - START"
#Start
../../../tools/command_client.pl -e etraxp129 -c "jam_trbv2 --trb -aRUN_XILINX_PROC /home/hadaq/tof/fpga/20120305_tof.stapl "

echo "Finished START"
