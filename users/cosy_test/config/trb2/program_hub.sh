#!/bin/bash

echo "Programming FPGAs - HUB"
#Hub
../../../tools/command_client.pl -e etraxp022 -c "jam_trbv2 --addon -aFP /home/hadaq/hub/hub2_fpga1_full_20110517.stp"
echo "Second FPGA"
../../../tools/command_client.pl -e etraxp022 -c "jam_trbv2 --addon -aFP /home/hadaq/hub/hub2_fpga2_full_20110523.stp"

echo "Finished HUB"
