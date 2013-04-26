#!/usr/bin/perl

use warnings;
use strict;

my $c;

$c=q|pkill -f "daq_evtbuild -m 1"|;
qx($c);

$c=q|pkill -f "daq_netmem -m 1"|;
qx($c);

exit if defined $ARGV[0];

$c=q|daq_evtbuild -m 1 -d file -o /hldfiles|;
system("$c &");
sleep 2;
$c=q|daq_netmem -m 1 -i UDP:192.168.1.1:50000|;
system("$c &");
