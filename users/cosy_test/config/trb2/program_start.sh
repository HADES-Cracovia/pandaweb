#!/bin/bash

echo "START: Programming FPGAs"

cmd="../../../tools/command_client.pl -e etraxp129 -c 'jam_trbv2 --trb -aRUN_XILINX_PROC /home/hadaq/tof/fpga/20120305_tof.stapl'"

echo "${cmd}"

#${cmd}

../../../tools/command_client.pl -e etraxp129 -c "jam_trbv2 --trb -aRUN_XILINX_PROC /home/hadaq/tof/fpga/20120305_tof.stapl "

echo "Finished START"
