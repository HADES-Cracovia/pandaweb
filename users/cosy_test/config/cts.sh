#!/bin/bash

echo "Doing CTS configuration"

trbcmd w 0x8000 0xa140 0x000f4240 # pulser freq
trbcmd setbit 0x8000 0xa101 0x2 # turn on pulser
