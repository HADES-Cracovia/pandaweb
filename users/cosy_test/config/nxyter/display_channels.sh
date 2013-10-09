#!/bin/sh

export PATH=/home/rich/TRB/trbsoft/trbnettools/binlocal:${PATH}

# first disable test_trigger_mode to allow reading
#REG20=$(trb_i2c r 0x8900 0x08 0x20 | awk '{print $2}')
#trb_i2c w 0x8900 0x08 0x20 0x00

echo "      01234567"
#echo "      --------"
for REG in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
do

VALUE=$(trb_i2c r 0x8900 0x08 $REG | awk '{print $2}' | base)
CHANNEL=$((8*$REG))
printf "%03d:  " $CHANNEL

for i in 0 1 2 3 4 5 6 7
do
	BIT=$(($VALUE>>$i&1))
	if [ $BIT -eq 0 ]
	then
		echo -n "*"
	else
		echo -n "_"
	fi
done
echo
done

# Restore Register 20
#trb_i2c w 0x8900 0x08 0x20 $REG20
