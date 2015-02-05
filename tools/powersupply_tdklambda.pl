#!/usr/bin/env perl
use strict;
use warnings;
use IO::Socket;
use Time::HiRes qw(usleep);

sub showUsage {
  print "usage: tdk.pl [ON|OFF|MEAS] HOST\n";
  exit;
}

my $cmd  = $ARGV[0] or showUsage;
my $peer = $ARGV[1] or showUsage;
my $socket;

$cmd = uc $cmd;

sub measure {
  my @values = ();

  usleep 1e5; print $socket "MEAS:VOLT?\n";
  my $volt = <$socket>;
  usleep 1e5; print $socket "MEAS:CURR?\n";
  my $curr = <$socket>;
  usleep 1e5; print $socket "OUTP:STAT?\n";
  my $state = <$socket>;

  chomp $volt;
  chomp $curr;
  chomp $state;

  print "$peer CH 0: $curr A @ $volt V ($state)\n";
}

sub switchPower {
  my $state = shift;
  $state = (uc($state) eq 'ON' ? 'ON' : 'OFF');
  usleep 1e5; print $socket "OUTP:STAT $state\n";
}

local $SIG{ALRM} = sub { die 'ERROR: Timed Out'; };
alarm 2;

$socket = IO::Socket::INET->new(PeerAddr => $peer, PeerPort => 8003, Proto => "tcp", Type => SOCK_STREAM) or die "ERROR: Cannot connect: $@";

if ($cmd eq "OFF" || $cmd eq "ON") {
  switchPower $cmd;
  measure;
} elsif ($cmd =~ m/^MEAS/) {
  measure;
} else {
  showUsage;
}


alarm 0;
