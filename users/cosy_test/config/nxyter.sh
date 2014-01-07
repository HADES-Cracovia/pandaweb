#!/bin/bash

cd nxyter

nxarr=(0x3800 0x3801 0x3802 0x3803)

for i in ${nxarr[*]}; do
	echo "nxyter: $i"
	res=$(trbcmd i $i 2> /dev/null | wc -l)
	if [ $res -eq 0 ]; then
		msg="${COLOR_RED}No nxyter found${COLOR_NC}"
		echo -e $msg
		continue
	fi
	./trb3_setup.sh $i
done

#./trb3_setup.sh 0x3800
#./trb3_setup.sh 0x3801
#./trb3_setup.sh 0x3802
#./trb3_setup.sh 0x3803

cd ..
