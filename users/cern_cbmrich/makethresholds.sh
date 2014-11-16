#!/bin/bash
rm padiwa_threshold_results.log
./write_thresholds.pl thresh/dummythresholds.thr -o 0


# ./run_thresh_on_system.pl \
#  --endpoints=0x0013,0x0021,0x0033,0x0041,0x0053,0x0061,0x0073,0x0081,0x0093,0x00a1,0x00b3,0x00c1,0x00d3,0x00e1,0x00f3,0x0101 \
#  --32channel --chains=0 --offset=0 --polarity 1 
# ./write_thresholds.pl thresh/dummythresholds.thr -o 0
# ./run_thresh_on_system.pl \
#  --endpoints=0x0012,0x0020,0x0032,0x0040,0x0052,0x0060,0x0072,0x0080,0x0092,0x00a0,0x00b2,0x00c0,0x00d2,0x00e0,0x00f2,0x0100 \
#  --32channel --chains=0 --offset=0 --polarity 1 
# ./write_thresholds.pl thresh/dummythresholds.thr -o 0
# ./run_thresh_on_system.pl \
#  --endpoints=0x0011,0x0023,0x0031,0x0043,0x0051,0x0063,0x0071,0x0083,0x0091,0x00a3,0x00b1,0x00c3,0x00d1,0x00e3,0x00f1,0x0103 \
#  --32channel --chains=0 --offset=0 --polarity 1 
# ./write_thresholds.pl thresh/dummythresholds.thr -o 0
# ./run_thresh_on_system.pl \
#  --endpoints=0x0010,0x0022,0x0030,0x0042,0x0050,0x0062,0x0070,0x0082,0x0090,0x00a2,0x00b0,0x00c2,0x00d0,0x00e2,0x00f0,0x0102 \
#  --32channel --chains=0 --offset=0 --polarity 1 

# 
# ./run_thresh_on_system.pl --endpoints=0x0010-0x0013,0x0020-0x0023,0x0030-0x0033,0x0040-0x0043,0x0050-0x0053,0x0060-0x0063,0x0070-0x0073,0x0080-0x0083,0x0090-0x0093,0x00a0-0x00a3,0x00b0-0x00b3,0x00c0-0x00c3,0x00d0-0x00d3,0x00e0-0x00e3,0x00f0-0x00f3,0x0100-0x0103\
#   --32channel --chains=0 --offset=0 --polarity 0 --tool ./thresholds_automatic.pl

./run_thresh_on_system.pl --endpoints=0x0010-0x0013,0x0020-0x0023,0x0030-0x0033,0x0040-0x0043,0x0050-0x0053,0x0060-0x0063,0x0070-0x0073,0x0080-0x0083,0x0090-0x0093,0x00a0-0x00a3,0x00b0-0x00b3,0x00c0-0x00c3,0x00d0-0x00d3,0x00e0-0x00e3,0x00f0-0x00f3,0x0100-0x0103\
  --32channel --chains=0 --offset=0 --polarity 1  --tool ./thresholds_new.pl 

./write_thresholds.pl padiwa_threshold_results.log -o 0