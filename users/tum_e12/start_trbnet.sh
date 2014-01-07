#!/bin/bash

# searching for proper environment
which trbnetd 2&> /dev/null
exstat="$?"

if [ "$exstat" -ne "1" ]; then
	echo "No path trbnetd found, please prepare environment first!"
	kill -SIGINT $$
else
	echo "Path to trbnetd found!"
fi

trbquery="trbnetd -i ${TRBNETID}"
trbpgrep=$(pgrep -f "${trbquery}")

# searching for existing trbnetd instances
if [ -n "${trbpgrep}" ]; then
	echo "Found running trbnetd daemons with ID=${TRBNETID}."
	read -n1 -p "Do you want to kill existing instances? (y/n) "
	echo
	if [[ $REPLY = [yY] ]]; then
		pkill -f "trbnetd -i ${TRBNETID}";
		echo "Old instances of trbnetd killed"
	else
		echo "You didn't answer yes, I can't proceed.";
		kill -SIGINT $$
	fi
fi

# running fresh trbnetd
trbnetd -i ${TRBNETID}			# (again it is the trb3 number)
TRBNETDPID=$(pgrep -f "${trbquery}")

echo "DAQ op server is running on ${DAQOPSERVER} (PID: ${TRBNETDPID})"

# checking TRB3 conenctions
echo -e "\n\$ trbcmd i 0xffff"
trbcmd i 0xffff
