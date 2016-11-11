#!/bin/bash

# CALTRIG = 1 | 13  1-daten, 13-internal pulser for TOT calibration

# make TDC calibration
# rm -f *.root *.cal; 
# export CALMODE=-1; export CALTRIG=1; go4analysis -rate -user $1 -number 50000000

# make TOT calibration
# rm -f *.root;
# export CALMODE=-1; CALTRIG=1; go4analysis -rate  -user $1 -number 50000000

rm -f *.root;
export CALMODE=0; CALTRIG=1; go4analysis -rate -user $1 -number 50000000

