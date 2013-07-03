#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;

my $help = "";
my $dataPath = "~/trbsoft/data";
my $source1 = "50000"; # don't use 50001
my $source2 = "50002"; # it is assigned for GbE debug
my $source3 = "50003";
my $source4 = "50004";
my $source5 = "50005";
my $label = "test";
my $time = -1;
my $c;

my $result = GetOptions (
    "h|help"    => \$help,
    "t|time=i"  => \$time#,
#    "l|label=s" => \$label,
#    "p|path=s"  => \$dataPath
    );

if($help) {
    print "Usage: start_readout.pl <time>\n\n";
    print "-h --help\tPrints the usage manual\n";
    print "-t --time\tDefine length of time in seconds for data taking (Default = -1)\n";
    print "\t\tFor unlimited data taking define <time> as -1.\n";
#    print "-l --label\tDefine label for the daq_evtbuild and daq_netmem processes (Default = test)\n";
#    print "-p --path\tDefine path for saving data (Default = ~/trbsoft/data\)\n";
    print "\n";
    exit;
}


$c=q|pkill -f "daq_evtbuild -S test"|; qx($c); # if any, kill existing daq_evtbuild
$c=q|pkill -f "daq_netmem -S test"|;   qx($c); # if any, kill existing daq_netmem


$c=q|xterm -geometry 122x14-0+0 -e bash -c 'daq_evtbuild -S test -m 4 -d file -o ~/trbsoft/data'|;
system("$c &");
sleep 1;
$c="xterm -geometry 82x10-0+210 -e bash -c 'daq_netmem -S test -m 4 -i UDP:127.0.0.1:50000 -i UDP:127.0.0.1:50002 -i UDP:127.0.0.1:50003 -i UDP:127.0.0.1:50004 '";
system("$c &");


if($time == -1) {
    print "Data taking will run until manual quit with Ctrl+C\n\n";
}
else {
    print "Data taking will run for $time seconds.\n\n";
    sleep $time;
    $c=q|pkill -f "daq_evtbuild -S test"|; qx($c);
    $c=q|pkill -f "daq_netmem -S test"|;   qx($c);
}
