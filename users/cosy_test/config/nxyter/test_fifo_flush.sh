#!/bin/sh

export PATH=/home/rich/TRB/trbsoft/trbnettools/binlocal:${PATH}

./setup.sh
./disable_all.sh 
./enable_channel.sh 0
./enable_channel.sh 1
./enable_channel.sh 2
./enable_channel.sh 3

trbcmd w 0x8900 0x8180 4

./enable_testtrigger.sh
./display_channels.sh
