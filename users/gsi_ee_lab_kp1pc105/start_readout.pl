#!/usr/bin/perl

use warnings;
use strict;

my $c;

$c=q|pkill -f "daq_evtbuild -m 1"|;
qx($c);

$c=q|pkill -f "daq_netmem -m 1"|;
qx($c);


$c=q|urxvt -geometry 122x14 -e bash -c 'daq_evtbuild -m 1 -d file -o /tmp'|;
system("$c &");
sleep 1;
$c="urxvt -geometry 82x10 -e bash -c 'daq_netmem -m 1 -i UDP:127.0.0.1:50002'";
system("$c &");
