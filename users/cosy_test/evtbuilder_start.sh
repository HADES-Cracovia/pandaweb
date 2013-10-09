#!/bin/bash

dest="/scratch/c/hldfiles"
sdest="/scratch/c/shldfiles"
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
extraopts=""
[ ${sden} -eq 1 ] && extraopts="$sdopts"

${HOME}/bin/evtbuilder_stop.sh

source ${HOME}/bin/trbnet_env.sh

exec uxterm -bg khaki -geometry 120x20+900+45 -e "/home/hadaq/bin/daq_evtbuild -m 3 -o ${dest} -x ${pref} -I 1 --ebnum 1 -q 32 -S test -d file ${extraopts}; read ; bash" &
pid=$!
echo $pid > ~/trbsoft/.daq_evtbuild.pid

sleep 1

exec uxterm -bg tan -geometry 120x20+900+345 -e "/home/hadaq/bin/daq_netmem -m 3 -i UDP:0.0.0.0:50000 -i UDP:0.0.0.0:50008 -i UDP:0.0.0.0:50009 -q 32 -d 1 -S test ; read ; bash " &
pid=$!
echo $pid > ~/trbsoft/.daq_netmem.pid

echo ${dest} > ${HOME}/trbsoft/.hldfilesdir
echo ${sdest} > ${HOME}/trbsoft/.shldfilesdir
