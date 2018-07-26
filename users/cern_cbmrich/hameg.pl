#!/usr/bin/env perl
use strict;
use warnings;
use IO::Socket;
use Time::HiRes qw(usleep);

sub showUsage {
  print "usage: hameg.pl [ON|OFF|ON#|OFF#|MEAS] HOST\n";
  print " where ON/OFF applies to all channels and ON#/OFF# to the number (1-4) specified\n";
  print "  example turn off 1 channel: ./hameg.pl OFF1 hameg01\n";

  exit;
}

my $cmd  = $ARGV[0] or showUsage;
my $peer = $ARGV[1] or showUsage;
my $socket;

$cmd = uc $cmd;


sub measure {
  my @values = ();
  for(my $chan = 1; $chan <= 4; $chan++) {
    usleep 1e5; print $socket "INST OUT$chan\n";
    
    usleep 1e5; print $socket "MEAS:VOLT?\n"; my $volt = <$socket>;
    usleep 1e5; print $socket "MEAS:CURR?\n"; my $curr = <$socket>;
    usleep 1e5; print $socket "OUTP:STAT?\n"; my $stat = <$socket>;

    chomp $volt;
    chomp $curr;
    chomp $stat;

    $stat = $stat eq "1" ? "ON" : "OFF";

    print "$peer CH $chan: $curr A @ $volt V ($stat)\n";
  }
}

sub switchPowerGen {
  my $state = shift;
  $state = (uc($state) eq 'ON' ? 'ON' : 'OFF');
  usleep 1e5; print $socket "OUTP:GEN $state\n";
}
  
sub switchPowerChan {
  my $chan = shift;
  my $state = shift;
  $state = (uc($state) eq 'ON' ? 'ON' : 'OFF');
  usleep 1e5; print $socket "INST OUT$chan\n";
  usleep 1e5; print $socket "OUTP:STAT $state\n";
}


local $SIG{ALRM} = sub { die 'ERROR: Timed Out'; };
alarm 3;

$socket = IO::Socket::INET->new(PeerAddr => $peer, PeerPort => 50000, Proto => "tcp", Type => SOCK_STREAM) or die "ERROR: Cannot connect: $@";

if ($cmd eq "ON" || $cmd eq "OFF") {
  switchPowerGen $cmd;
  measure;
} elsif ($cmd =~ m/^(ON|OFF)([1-4])$/) {
  switchPowerChan $2, $1;
  measure;
} elsif ($cmd =~ m/^MEAS/) {
  measure;
} else {
  showUsage;
}

alarm 0;
