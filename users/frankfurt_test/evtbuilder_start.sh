#!/bin/bash

dest="/local/tmp"
sdest="/local/tmp"
tmpdir="/local/tmp/evtbuild"
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


[ ! -e $tmpdir ] && mkdir -p $tmpdir
cd $tmpdir


exec uxterm -bg khaki -geometry 120x20+0+45 -e "/d/jspc22/trb/git/daqdata/hadaq/daq_evtbuild -m 1 -o ${dest} -x ${pref} -I 1 --ebnum 1 -q 32 -S test -d file ${extraopts}; read; bash" &
pid=$!
echo $pid > $tmpdir/.daq_evtbuild.pid

sleep 1

exec uxterm -bg tan -geometry 120x20+0+345 -e "/d/jspc22/trb/git/daqdata/hadaq/daq_netmem -m 1 -i UDP:0.0.0.0:50000 -q 32 -d 1 -S test ;  " &
pid=$!
echo $pid > $tmpdir/.daq_netmem.pid

echo ${dest} > $tmpdir/.hldfilesdir
echo ${sdest} > $tmpdir/.shldfilesdir
