#!/bin/bash

~/trbsoft/daqtools/padiwa.pl 0x3802 0 disable 0xfffe   #only first channel active
~/trbsoft/daqtools/padiwa.pl 0x3802 0 monitor 0x18     #use or of all inputs, stretched to >16ns as trigger out
~/trbsoft/daqtools/padiwa.pl 0x3802 0 comp 0	       #no temperature compensation
~/trbsoft/daqtools/padiwa.pl 0x3802 0 invert 0         #no inverter on inputs
~/trbsoft/daqtools/padiwa.pl 0x3802 0 stretch 0        #no stretching of raw signals
~/trbsoft/daqtools/padiwa.pl 0x3802 0 pwm 0 8a00       #pwm of first channel to 1.778mV



