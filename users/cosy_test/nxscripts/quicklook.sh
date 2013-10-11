#!/bin/bash

watch -n 1 " \
trbcmd -d1 r 0x3800 0x8124; \
trbcmd -d1 r 0x3800 0x8125; \
trbcmd -d1 r 0x3800 0x8162; \
"

