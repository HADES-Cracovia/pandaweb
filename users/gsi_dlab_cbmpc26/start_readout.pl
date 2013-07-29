#!/usr/bin/perl

use warnings;
use strict;

my $c;

$c=q|pkill -f "daq_evtbuild -m 1"|;
qx($c);

$c=q|pkill -f "daq_netmem -m 1"|;
qx($c);


$c=q|xterm -geometry 122x14-0+0 -e bash -c 'daq_evtbuild -m 1 -d file -o /tmp'|;
system("$c &");
sleep 1;
$c="xterm -geometry 82x10-0+210 -e bash -c 'daq_netmem -m 1 -i UDP:127.0.0.1:50000'";
system("$c &");
