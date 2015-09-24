#!/usr/bin/perl

use warnings;
use strict;
use Parallel::ForkManager;
use Net::Ping;
use Data::Dumper;

my @trbs = (78, 84, 101, 102);

my $map = {
 1 => { trb =>  84, sys => "TDC 00"},
 2 => { trb => 101, sys => "TDC 01"},
 3 => { trb =>  78, sys => "TDC 02"},
 4 => { trb => 102, sys => "TDC 03"},
 0 => { trb =>  61, sys => "CTS"},
};


my $MAX_PROCESSES=50;
my $pm = Parallel::ForkManager->new($MAX_PROCESSES);

#my $p = Net::Ping->new();

#print Dumper keys %$map;
#exit;
foreach my $ct (keys %$map) {
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
    my $sysnum = sprintf "0x80%.2x", $ct;
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
