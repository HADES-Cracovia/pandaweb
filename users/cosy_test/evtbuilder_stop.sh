#!/bin/bash

tmpdir="/tmp/eventbuild"

killpid() {
	local pidf=$1

	[ -e $pidf ] && pidv=$(cat $pidf)
#	echo "Found PID=$pidv"

	if [ -n "${pidv}" ]; then
#	        echo "Nice way with ps -fp"

		pidexists=$(ps -fp $pidv --no-headers | grep "daq_netmem\|daq_evtbuild" | wc -l)

		[ "${pidexists}" -ne 0 ] && kill -2 ${pidv} || echo "Doesn't exists!"
	        rm ${pidf} -v
#	else
#		echo "No PID file, kill by hand..."
	fi
}

pidf=$tmpdir/.daq_evtbuild.pid
killpid $pidf

pidf=$tmpdir/.daq_netmem.pid
killpid $pidf

