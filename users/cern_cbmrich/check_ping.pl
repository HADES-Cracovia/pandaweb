#!/usr/bin/perl

use warnings;
use strict;
use Parallel::ForkManager;
use Net::Ping;


my $map = {
 0 => { trb => 105, sys => "PMT 1-4  "},
 1 => { trb =>  89, sys => "PMT 5-8  "},
 2 => { trb =>  57, sys => "PMT 9-12 "},
 3 => { trb =>  99, sys => "PMT 13-16"},
 4 => { trb =>  73, sys => "PMT 17-20"},
 5 => { trb => 102, sys => "PMT 21-24"},
 6 => { trb =>  83, sys => "PMT 25-28"},
 7 => { trb =>  78, sys => "PMT 29-32"},
 8 => { trb => 104, sys => "PMT 33-36"},
 9 => { trb =>  74, sys => "PMT 37-40"},
10 => { trb =>  72, sys => "PMT 41-44"},
11 => { trb =>  47, sys => "PMT 45-48"},
12 => { trb =>  59, sys => "PMT 49-52"},
13 => { trb =>  84, sys => "PMT 53-56"},
14 => { trb =>  97, sys => "PMT 57-60"},
15 => { trb =>  29, sys => "PMT 61-64"},
16 => { trb => 101, sys => "Lemo Inp."},
-1 => { trb =>  56, sys => "CTS      "},
};


my $MAX_PROCESSES=50;
my $pm = Parallel::ForkManager->new($MAX_PROCESSES);

#my $p = Net::Ping->new();

foreach my $ct (keys $map) {
    #my $num = sprintf "%3.3d", $ct;
    my $trbnum= $map->{$ct}->{trb};
    my $num = sprintf "%3.3d", $trbnum;
    my $host= "trb" . $num;
    my $system = $map->{$ct}->{sys};
    #print "192.168.0.$ct   $host.gsi.de $host\n";
    #my $r = $p->ping($host,1);
    my $c= "ping -W1 -c1 $host";

    my $pid = $pm->start and next;


    #my $p = Net::Ping->new("udp", 1);
    #my $r = $p->ping("192.168.0.56");
    #$p->close();
    #print "result: $r\n";

    my $r = qx($c);
    my $sysnum = sprintf "0x80%s", $ct < 10 ? "0$ct" :  $ct;
    $sysnum = "0x7999" if $ct == -1;
    #printf "$sysnum, system: %-8s, trb: $host ", $system;
    printf "$sysnum  $host  %-8s ", $system;
    if (grep /64 bytes/, $r) {
	print "is alive.\n";
    }
    else {
	print "is not alive.\n";
   }

    $pm->finish; # Terminates the child process
}

$pm->wait_all_children;
#$p->close();
