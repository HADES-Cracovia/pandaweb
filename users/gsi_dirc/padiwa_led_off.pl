#!/usr/bin/perl 

use strict;
use warnings;
use Parallel::ForkManager;

my $MAX_PROCESSES=50;
my $pm = Parallel::ForkManager->new($MAX_PROCESSES);

my @pad0 =(0x2000,0x2001,0x2004,0x2007,0x2009,0x200a,0x200c,0x200f,0x2011,0x2012,0x2013);
my @pad1 =(0x2000,0x2004,0x2005,0x2006,0x2007,0x2008,0x2009,0x200e);
my @pad2 =(0x2004,0x2006,0x2008,0x2009,0x200a,0x200e,0x2010);


foreach my $b (@pad0) {
    my $pid = $pm->start and next;
    my $c = sprintf("../../tools/padiwa.pl 0x%04x 0 led 0x10 >/dev/null",$b);
    system($c);
    $pm->finish;
  }
$pm->wait_all_children;

foreach my $b (@pad1) {
    my $pid = $pm->start and next;
    my $c = sprintf("../../tools/padiwa.pl 0x%04x 1 led 0x10 >/dev/null",$b);
    system($c);
    $pm->finish;
  }
$pm->wait_all_children;

foreach my $b (@pad2) {
    my $pid = $pm->start and next;
    my $c = sprintf("../../tools/padiwa.pl 0x%04x 2 led 0x10 >/dev/null",$b);
    system($c);
    $pm->finish;
}  
$pm->wait_all_children;

print "finished switching off all led for new Padiwa-Firmware (>= 2014.11.21)\n";
