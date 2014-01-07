#!/bin/bash

dest="/scratch/c/hldfiles"
sdest="/scratch/c/shldfiles"
tmpdir="/tmp/eventbuild"
pref="te"
sden=0

usage() {
	echo "Usage: $0 [-d <hlddir>] [-s <shlddir>] [-p <te|be|ca>] [-t] [-h]"
	echo "  -t -- scale down"
	echo " Defaults:"
	echo "  -d=${dest}"
	echo "  -s=${sdest}"
	echo "  -p=${pref}"
}

while getopts "d:s:p:th" opt; do
	case "${opt}" in
		t)
			sden=1
			;;
		d)
			dest=${OPTARG}
			;;
		s)
			sdest=${OPTARG}
			;;
		p)
			pref=${OPTARG}
			;;
		h)
			usage
			;;
		*)
			exit -1
			;;
	esac
done

sdopts="--resdownscale 20 --resnumevents 2000 --respath ${sdest} --ressizelimit 80"
extraopts="--online"
[ ${sden} -eq 1 ] && extraopts="$sdopts"

$(dirname ${BASH_SOURCE})/evtbuilder_stop.sh

[ ! -e $tmpdir ] && mkdir -p $tmpdir
cd $tmpdir

# source ${HOME}/bin/trbnet_env.sh

#Variants:
#1 without CTS
#2 normal mode with everything
#3 without TRB2

#exec uxterm -bg khaki -geometry 120x19+945+35 -e "/home/hadaq/bin/daq_evtbuild -m 2 -o ${dest} -x ${pref} -I 1 --ebnum 1 -q 32 -S test -d file ${extraopts}; read; bash" &
exec uxterm -bg khaki -geometry 120x20+900+45 -e "/home/hadaq/bin/daq_evtbuild -m 3 -o ${dest} -x ${pref} -I 1 --ebnum 1 -q 32 -S test -d file ${extraopts}; read ; bash" &
#exec uxterm -bg khaki -geometry 120x20+900+45 -e "/home/hadaq/bin/daq_evtbuild -m 2 -o ${dest} -x ${pref} -I 1 --ebnum 1 -q 32 -S test -d file ${extraopts}; read ; bash" &
pid=$!
echo $pid > $tmpdir/.daq_evtbuild.pid

sleep 1

#exec uxterm -bg tan -geometry 120x19+945+320 -e "/home/hadaq/bin/daq_netmem -m 2 -i UDP:0.0.0.0:50008 -i UDP:0.0.0.0:50009 -q 32 -d 1 -S test ;  " &
exec uxterm -bg tan -geometry 120x20+900+345 -e "/home/hadaq/bin/daq_netmem -m 3 -i UDP:0.0.0.0:50000 -i UDP:0.0.0.0:50008 -i UDP:0.0.0.0:50009 -q 32 -d 1 -S test ; read ; bash " &
#exec uxterm -bg tan -geometry 120x20+900+345 -e "/home/hadaq/bin/daq_netmem -m 2 -i UDP:0.0.0.0:50000  -i UDP:0.0.0.0:50009 -q 32 -d 1 -S test ; read ; bash " &
pid=$!
echo $pid > $tmpdir/.daq_netmem.pid

echo ${dest} > $tmpdir/.hldfilesdir
echo ${sdest} > $tmpdir/.shldfilesdir
