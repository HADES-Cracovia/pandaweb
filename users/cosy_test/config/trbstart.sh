#!/bin/bash

echo "Setting up Start TRB"


#execute this on TRB:

TRBNUM=129

#../../../tools/command_client.pl -e etraxp$TRBNUM -c 'spi_trbv2_rl /home/hadaq/start_and_veto/thresholds_test'
#../../../tools/command_client.pl -e etraxp$TRBNUM -c 'spi_trbv2_rl /home/hadaq/start/run.cfg'
../../../tools/command_client.pl -e etraxp$TRBNUM -c 'spi_trbv2_rl /home/hadaq/start/all_pmt.cfg'

../../../tools/command_client.pl -e etraxp$TRBNUM -c "cd /home/hadaq/scripts/; ./trbv2_TDCs_configure.sh ${TRBNUM}"

# hi res for Start
#../../../tools/command_client.pl -e etraxp$TRBNUM -c 'rw_trbv2 --trb w 0 c2 007E0100; rw_trbv2 --trb w 0 c0 0a000000; rw_trbv2 --trb w 0 c3 00000100'

# low res for TOF                                                                | here is the change
../../../tools/command_client.pl -e etraxp$TRBNUM -c 'rw_trbv2 --trb w 0 c2 007E0000; rw_trbv2 --trb w 0 c0 0a000000; rw_trbv2 --trb w 0 c3 00000100'


