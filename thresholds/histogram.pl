#!/usr/bin/perl
use warnings;
use strict;

use Getopt::Long;
use Pod::Usage;
use HADES::TrbNet;
use Data::Dumper;
use Time::HiRes qw(usleep);
use POSIX;

my $man = 0;
my $help = 0;
my $verbose = 0;
my $endpoint = '0x0200';
my $chain = 0;
my $channel32 = 1;
my @channels = (0);
my $from = -10;
my $to = 10;
my $delta = 1;

Getopt::Long::Configure(qw(gnu_getopt));
GetOptions(
           'help|h' => \$help,
           'man' => \$man,
           'verbose|v+' => \$verbose,
           'chain|c=i' => \$chain,
           '32channel|32!' => \$channel32,
           'endpoint|e=s' => \$endpoint,
           'from|f=s' => \$from,
           'to|t=s' => \$to,
           'delta|d=s' => \$delta,
          ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;


my $mVscale = 3330;

# check/convert inputs
$from = int(0xffff*$from/$mVscale);
$to = int(0xffff*$to/$mVscale);
$delta = int(0xffff*$delta/$mVscale);

unless($chain =~ /^\d+$/) {
  die "wrong number format for chain parameter: \"$chain\"";
}

if ($endpoint !~ /^0x/) {
  print "wrong format for enpoint number $endpoint, should be 0x0 - 0xffff, use hex notation with 0x\n";
  exit 1;
}
$endpoint = hex($endpoint);

# determine the right hitregister channel
# for one threshold channel
my $hitchannel_multiplicator = $channel32 ? 2 : 1;
my $hitregister = 0xc001 + 16*$chain*$hitchannel_multiplicator;


# init trb, set the padiwa chain
trb_init_ports() or die trb_strerror();
trb_register_write($endpoint, 0xd410, 1 << $chain) or die trb_strerror();

&main;

sub main {
  
  &make_histo();
}

sub make_histo {
  my %histo = ();
  my %thresh = &read_thresholds();
  my %thresh_save = %thresh;
  for(my $d=$from;$d<$to;$d+=$delta) {
    foreach my $ch (@channels) {
      $thresh{$ch} = $thresh_save{$ch} + $d;
    }
    write_thresholds(%thresh);
    my %hitrate = &get_hitrate;
    foreach my $ch (@channels) {
      my $hit_ch = $hitchannel_multiplicator*$ch;
      if($channel32) {
        printf("%04.2f %07.0f %07.0f\n",
               $mVscale*$thresh{$ch}/0xffff,
               $hitrate{$hit_ch},
               $hitrate{$hit_ch+1}
              )
      }
    }
  }

  write_thresholds(%thresh_save);
  %thresh_save = &read_thresholds();
  #print Dumper(\%thresh_save);
  return %histo;
}

sub get_hitrate {
  my $sleeptime = 80e3;
  my $bitmask = 0xffffff;
  my $mem1 = trb_registertime_read_mem($endpoint, $hitregister, 0, 32);
  usleep($sleeptime);
  my $mem2 = trb_registertime_read_mem($endpoint, $hitregister, 0, 32);
  $mem2 = $mem2->{$endpoint};
  $mem1 = $mem1->{$endpoint};
  my %hitrate = ();
  foreach my $ch (0..31) {
    my $hits1 = $mem1->{'value'}->[$ch] & $bitmask;
    my $hits2 = $mem2->{'value'}->[$ch] & $bitmask;
    my $t1 = $mem1->{'time'}->[$ch];
    my $t2 = $mem2->{'time'}->[$ch];
    # catch a possible overflow of the hitscaler
    my $rate = $hits2>=$hits1 ? $hits2-$hits1 :
      $hits2-$hits1+$bitmask;
    # catch a overflow in the 16bit clock (16us ticks)
    my $timediff = 16*($t2>=$t1 ? $t2-$t1 : $t2-$t1+0xffff);

    $hitrate{$ch} = 1e6*$rate/$timediff;
    #printf("%02d %04d %06d %.0f Hz %08x %08x\n",$ch, $rate, $timediff, $hitrate{$ch},  $hits1, $hits2);

  }
  return %hitrate;
}

sub read_thresholds {
  my $fixed_bits = 0x00000000;
  my %ret = ();
  foreach my $ch (@channels) {
    my $command = $fixed_bits | ($ch << 16);
    my $thresh = send_command($command);
    #printf("%08x %02d 0x%04x %4.3f\n",$command, $ch, $thresh, 3330*$thresh/0xffff);
    $ret{$ch} = $thresh;
  }
  return %ret;
}

sub write_thresholds {
  my %thresh = @_;
  my $fixed_bits = 0x00800000;
  foreach my $ch (@channels) {
    my $command = $fixed_bits | ($ch << 16) | $thresh{$ch};
    send_command($command);
  }
  # sleep 50ms to settle thresholds
  usleep(50e3);
}


sub send_command {
  my $command = shift;

  trb_register_write($endpoint, 0xd400, $command) or
    die trb_strerror();

  trb_register_write($endpoint, 0xd411, 0x1) or
    die trb_strerror();

  my $res = trb_register_read($endpoint, 0xd412);
  die trb_strerror() unless defined $res;
  return $res->{$endpoint} & 0xffff;
}




__END__

=head1 NAME

histogram.pl - Plot threshold against TDC hits

=head1 SYNOPSIS

histogram.pl -e 0x0200 -c 0 -f -10 -t 10 -d 1

 Options:
   -h, --help     brief help message
   -v, --verbose  be verbose to STDERR
   -e, --endpoint TRB endpoint (TDC)
   -c, --chain    PaDiWa board in chain
   -f, --from     relative start to scan in mV
   -t, --to       relative stop to scan in mV
   -d, --delta    increment in mV

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exit.

=item B<--verbose>

Print some information what is going on.

=back

=head1 DESCRIPTION

TODO

=cut
