#!/usr/bin/perl 

use strict;
use warnings;

use Parallel::ForkManager;

my $arg=$ARGV[0];

unless ($arg) {
    print "usage:
./prepare_padiwas_invert_leds.pl <\"list of hex TRBNet addresses, space separated\">
";
exit;
}

my @padiwas = split /\s+/, $arg;

my $MAX_PROCESSES = 100;
my $pm = Parallel::ForkManager->new($MAX_PROCESSES);

print "padiwas: inverting padiwa outputs: ";

foreach (@padiwas) { 
    my $pid = $pm->start and next;
    print "$_ ";
	 #y $c="/home/hadaq/trbsoft/daqtools/padiwa.pl $_ 0 invert 0xffff >/dev/null";
    my $c="/home/hadaq/trbsoft/daqtools/padiwa.pl $_ 0 invert 0xffff 1>/dev/null";
	 #my $c="/home/hadaq/trbsoft/daqtools/padiwa.pl $_ 0 temp";
    my $r = qx($c);
    die "could not execute command $c" if $?;
    print $r;

    $pm->finish; # Terminates the child process 
};
$pm->wait_all_children;
print "\n";

print "padiwas: turn off all leds: ";

foreach (@padiwas) { 
    my $pid = $pm->start and next;
    print "$_ ";
    my $c="/home/hadaq/trbsoft/daqtools/padiwa.pl $_ 0 led 0x10 >/dev/null";
    qx($c); die "could not execute command $c" if $?;
    $pm->finish; # Terminates the child process 
};

$pm->wait_all_children;
print "\n";

print "padiwas: set temp compensation to 0x02c0: ";

foreach (@padiwas) { 
    my $pid = $pm->start and next;
    print "$_ ";
    my $c="/home/hadaq/trbsoft/daqtools/padiwa.pl $_ 0 comp 0x02c0 >/dev/null";
    qx($c); die "could not execute command $c" if $?;
    $pm->finish; # Terminates the child process 
};

$pm->wait_all_children;

print "\n";


