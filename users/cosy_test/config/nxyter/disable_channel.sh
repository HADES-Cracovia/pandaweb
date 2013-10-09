#!/bin/sh

export PATH=/home/rich/TRB/trbsoft/trbnettools/binlocal:${PATH}

if [ -z "$1" ]
then
	echo "Usage: $0 ChannelID"
	exit 0;
fi

# first disable test_trigger_ mode to allow reading
REG20=$(trb_i2c r 0x3800 0x08 0x20 | awk '{print $2}')
trb_i2c w 0x3800 0x08 0x20 0x00

REGISTER=$(($1/8))
MASK=$((2**($1-8*$REGISTER)))

echo "Register: $REGISTER Mask: $MASK"

CURRENT=$(trb_i2c r 0x3800 0x08 $REGISTER | awk '{print $2}' | base)
NEW=$(($CURRENT|$MASK))

echo "$CURRENT -> $NEW"
trb_i2c w 0x3800 0x08 $REGISTER $NEW

# Restore Register 20
trb_i2c w 0x3800 0x08 0x20 $REG20
