#!/bin/sh

i=0
while [ $i -lt 129 ] 
do
	VALUE=$(trb_i2c r 0x3800 0x08 42 | awk '{print $2}')
	echo "$i : $VALUE"
	trb_i2c w 0x3800 0x08 42 $VALUE
	i=$((i+1))
done

