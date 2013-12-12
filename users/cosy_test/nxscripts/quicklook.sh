#!/bin/bash

watch -n 1 \
"echo Hit rate [Hz]; trbcmd -D r 0xfe49 0x8124; \
echo Clocks [Hz]; trbcmd -D r 0xfe49 0x8125; \
echo Trigger rate [Hz]; trbcmd -D r 0xfe49 0x8162; \
"

