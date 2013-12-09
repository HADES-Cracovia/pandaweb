#!/bin/bash

echo "HUB: Programming FPGA #1"
#Hub
cmd="../../../tools/command_client.pl -e etraxp022 -c 'jam_trbv2 --addon -aFP /home/hadaq/hub/hub2_fpga1_full_20110517.stp'"
echo ${cmd}
#{cmd}
../../../tools/command_client.pl -e etraxp022 -c 'jam_trbv2 --addon -aFP /home/hadaq/hub/hub2_fpga1_full_20110517.stp'
echo "HUB: Programming FPGA #2"

cmd="../../../tools/command_client.pl -e etraxp022 -c 'jam_trbv2 --addon -aFP /home/hadaq/hub/hub2_fpga2_full_20110523.stp'"
echo ${cmd}
#${cmd}
../../../tools/command_client.pl -e etraxp022 -c 'jam_trbv2 --addon -aFP /home/hadaq/hub/hub2_fpga2_full_20110523.stp'
echo "Finished HUB"
