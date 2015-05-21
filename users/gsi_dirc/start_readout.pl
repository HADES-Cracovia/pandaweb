#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;

my $help = "";
my $dataPath = "/d/may2015/";
my $label = "test";
my $time = -1;
my $name = "cc";
my $c;

my $result = GetOptions (
    "h|help"    => \$help,
    "t|time=i"  => \$time,
    "l|label=s" => \$label,
    "n|filename=s" => \$name,
    "p|path=s"  => \$dataPath
    );

if($help) {
    print "Usage: start_readout.pl <time>\n\n";
    print "-h --help\tPrints the usage manual\n";
    print "-t --time\tDefine length of time in seconds for data taking (Default = -1)\n";
    print "\t\tFor unlimited data taking define <time> as -1.\n";
    print "-l --label\tDefine label for the daq_evtbuild and daq_netmem processes (Default = test)\n";
    print "-p --path\tDefine path for saving data (Default = ~/trbsoft/data\)\n";
    print "\n";
    exit;
}


$c=qq|pkill -f "daq_evtbuild -S $label"|; qx($c); # if any, kill existing daq_evtbuild
$c=qq|pkill -f "daq_netmem -S $label"|;   qx($c); # if any, kill existing daq_netmem


$c=qq|xterm -geometry 122x15-0+0 -e bash -c 'daq_evtbuild -S $label -m 13 -x $name --filesize 512 -d file -o $dataPath'|;
#$c=qq|xterm -geometry 122x16-0+0 -e bash -c 'daq_evtbuild -S $label -m 23 -x $name -d file -o $dataPath'|;
#print $c;

system("$c &");

sleep 1;
$c=qq"xterm -geometry 82x45-0+210 -e bash -c 'daq_netmem -S $label -m 13 -i UDP:127.0.0.1:49999 -i UDP:127.0.0.1:50000 -i UDP:127.0.0.1:50001 -i UDP:127.0.0.1:50002 -i UDP:127.0.0.1:50003 -i UDP:127.0.0.1:50004 -i UDP:127.0.0.1:50005 -i UDP:127.0.0.1:50006 -i UDP:127.0.0.1:50007 -i UDP:127.0.0.1:50008 -i UDP:127.0.0.1:50009 -i UDP:127.0.0.1:50010 -i UDP:127.0.0.1:50011'";





#$c=qq"xterm -geometry 82x44-0+234 -e bash -c 'daq_netmem -S $label -m 23 -i UDP:127.0.0.1:50000 -i UDP:127.0.0.1:50001 -i UDP:127.0.0.1:50002 -i UDP:127.0.0.1:50003 -i UDP:127.0.0.1:50004 -i UDP:127.0.0.1:50005 -i UDP:127.0.0.1:50006 -i UDP:127.0.0.1:50007 -i UDP:127.0.0.1:50008 -i UDP:127.0.0.1:50009 -i UDP:127.0.0.1:50010 -i UDP:127.0.0.1:50011 -i UDP:127.0.0.1:50012 -i UDP:127.0.0.1:50013 -i UDP:127.0.0.1:50014 -i UDP:127.0.0.1:50015 -i UDP:127.0.0.1:50016 -i UDP:127.0.0.1:50017 -i UDP:127.0.0.1:50018 -i UDP:127.0.0.1:50019 -i UDP:127.0.0.1:50020 -i UDP:127.0.0.1:50021 -i UDP:127.0.0.1:50022; sleep 2'";


#$c=qq"xterm -geometry 82x17-0+210 -e bash -c 'daq_netmem -S $label -m 2 -i UDP:127.0.0.1:50000 -i UDP:127.0.0.1:50002'";
system("$c &");

print "Saving data to $dataPath\n";

if($time == -1) {
    print "Data taking will run until manual quit with Ctrl+C\n\n";
}
else {
    print "Data taking will run for $time seconds.\n\n";
    sleep $time;
    $c=qq|pkill -f "daq_evtbuild -S $label"|; qx($c);
    $c=qq|pkill -f "daq_netmem -S $label"|;   qx($c);
}
