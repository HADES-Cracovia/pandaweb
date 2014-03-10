#!/bin/bash
ENDPOINT="0x0200"
CHAIN="0"
padiwa.pl $ENDPOINT $CHAIN uid
padiwa.pl $ENDPOINT $CHAIN temp
padiwa.pl $ENDPOINT $CHAIN invert 0xaaaa

THR_LOW="0x07ef"
THR_HIGH="0xd7ac"

padiwa.pl $ENDPOINT $CHAIN pwm 0 $THR_LOW
padiwa.pl $ENDPOINT $CHAIN pwm 1 $THR_HIGH
padiwa.pl $ENDPOINT $CHAIN pwm 2 $THR_LOW
padiwa.pl $ENDPOINT $CHAIN pwm 3 $THR_HIGH
padiwa.pl $ENDPOINT $CHAIN pwm 4 $THR_LOW
padiwa.pl $ENDPOINT $CHAIN pwm 5 $THR_HIGH
padiwa.pl $ENDPOINT $CHAIN pwm 6 $THR_LOW
padiwa.pl $ENDPOINT $CHAIN pwm 7 $THR_HIGH
