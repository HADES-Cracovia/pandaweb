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


#if [ "$num" -eq "1" ] ; then
  exec uxterm -fg black -bg khaki -geometry 120x20+0+45 -e "daq_evtbuild -m 1 -o ${dest} -x ${pref} -I 1 --ebnum 1 -q 32 -S test -d file; read; bash" &
#fi
#if [ "$num" -eq "2" ]; then
#  exec uxterm -fg black -bg khaki -geometry 120x20+0+45 -e "/d/jspc22/trb/git/daqdata/hadaq/daq_evtbuild -m 2 -o ${dest} -x ${pref} -I 1 --ebnum 1 -q 32 -S test -d file \
#${extraopts}; read; bash" &
#fi

pid=$!
echo $pid > $tmpdir/.daq_evtbuild.pid

sleep 1

#if [ "$num" -eq "1" ]; then
  exec uxterm -fg black -bg tan -geometry 120x20+0+345 -e "daq_netmem -m 1 -i UDP:0.0.0.0:50000 -q 32 -d 1 -S test ;  " &
#fi

#if [ "$num" -eq "2" ]; then
#  exec uxterm -fg black -bg tan -geometry 120x20+0+345 -e "/d/jspc22/trb/git/daqdata/hadaq/daq_netmem -m 2 -i UDP:0.0.0.0:50000 -i UDP:0.0.0.0:50003 -q 32 -d 1 -S test ;  " &
#fi
pid=$!
echo $pid > $tmpdir/.daq_netmem.pid

echo ${dest} > $tmpdir/.hldfilesdir
echo ${sdest} > $tmpdir/.shldfilesdir
