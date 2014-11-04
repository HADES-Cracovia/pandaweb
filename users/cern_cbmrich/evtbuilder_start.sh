#!/bin/bash

dest="/mnt/data/tmp"
sdest="/mnt/data/tmp"
tmpdir="/mnt/data/tmp/evtbuild"
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

while getopts "n:d:s:p:th" opt; do
	case "${opt}" in
		t)
			sden=1
			;;
		d)
			dest=${OPTARG}
			;;
		n)
			num=${OPTARG}
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


  exec uxterm -fg black -bg khaki -geometry 120x20+0+45 -e "/home/hadaq/bin/daq_evtbuild -m 18 -o ${dest} -x ${pref} -I 1 --ebnum 1 -q 32 -S test -d file \
${extraopts}; read; bash" &


pid=$!
echo $pid > $tmpdir/.daq_evtbuild.pid

sleep 1

  exec uxterm -fg black -bg tan -geometry 120x20+0+345 -e "/home/hadaq/bin/daq_netmem -m 18 -i UDP:0.0.0.0:50000 -i UDP:0.0.0.0:50001 -i UDP:0.0.0.0:50002 -i UDP:0.0.0.0:50003 -i UDP:0.0.0.0:50004 -i UDP:0.0.0.0:50005 -i UDP:0.0.0.0:50006 -i UDP:0.0.0.0:50007 -i UDP:0.0.0.0:50008 -i UDP:0.0.0.0:50009 -i UDP:0.0.0.0:50010 -i UDP:0.0.0.0:50011 -i UDP:0.0.0.0:50012 -i UDP:0.0.0.0:50013 -i UDP:0.0.0.0:50014 -i UDP:0.0.0.0:50015 -i UDP:0.0.0.0:50016 -i UDP:0.0.0.0:50017 -q 32 -d 1 -S test ;  " &

pid=$!
echo $pid > $tmpdir/.daq_netmem.pid

echo ${dest} > $tmpdir/.hldfilesdir
echo ${sdest} > $tmpdir/.shldfilesdir
