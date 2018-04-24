#!/usr/bin/perl
use warnings;
use strict;
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use Data::Dumper;

use lib "/home/hadaq/trbsoft/daqtools/dmon/code";
use Dmon;

my $dirich = 0x1234;

$dirich = $ARGV[0];

unless ($ARGV[0]) {
  print "usage: $0 <DiRICH--TrbNet-Address>\n";
  exit;
}

$dirich = hex($dirich);

my $throffset = 0xa000;
#my $monitor = 0xdfc0;
my $monitor = 0xc001;

my $first_channel = 0;
my $last_channel = 31;

my $default_threshold = 0x6000;

#my $absolute_max_threshold = 0x8000;
my $absolute_min_threshold = 0x1000;

my @res; my $res; my $rh_res;

trb_init_ports() or die trb_strerror();

# enable monitor counters
$res = trb_register_write($dirich, 0xdf80 , 0xffffffff);
if(!defined $res) {
    $res = trb_strerror();
    print "error output: $res\n";
}


my $fixed_bits = 0x00800000;
my $shift_bits = 0;
my $channel_shift = 24;
my $command;
my $chain=0;

my $READ  = 0x0<<20; # bits to set for a read command
my $WRITE = 0x8<<20; # bits to set for a write command
my $REGNR = 24; # number of bits to shift for the register number


for my $channel (0 .. 31) {
  $chain = ($channel <16) ? 0 : 1;
  #($channel<<$REGNR | $WRITE | ($data&0xffff));
  # sendcmd($channel<<$REGNR | $WRITE | ($data&0xffff));
  #$command = $fixed_bits | ((0x10| ($channel&0xf)) << $channel_shift) | (($default_threshold+$channel) << $shift_bits);
  $command = ($channel&0xf)<<$REGNR | $WRITE | ($default_threshold&0xffff);
  #print "$command\n";
  Dmon::PadiwaSendCmd($command,$dirich, $chain);
  usleep(10E3);
  #trb_register_write($dirich, $throffset + $channel , $default_threshold);
  #$rh_res = trb_register_read($dirich, $throffset + $channel);
}
#exit;
usleep (1E5);

my $boundaries = {};

for my $channel ($first_channel .. $last_channel) {
#for my $channel (30 .. 31) {

    my $hit_zero_diff_flag = 0;

    my $lower_threshold = 0x6f80;
    my $upper_threshold = 0x9000;
    my $reasonable_upper_threshold = 0x7800;
    my $thresh_increment = 0x8;

  THRESH_LOOP:    for (my $thresh = $lower_threshold ; $thresh <= $upper_threshold; $thresh += $thresh_increment) {
      $chain = ($channel <16) ? 0 : 1;
      #$command = $fixed_bits | ( (0x10|($channel&0xf)) << $channel_shift) | ($thresh << $shift_bits);
      $command = ($channel & 0xf)<<$REGNR | $WRITE | ($thresh&0xffff);
      #print "chain: $chain\n";
      Dmon::PadiwaSendCmd($command,$dirich, $chain);
      ##trb_register_write($dirich, $throffset + $channel , $thresh);
      undef $rh_res;
      my @hits = ();
      foreach (1..2) {
	  $rh_res = trb_register_read($dirich, $monitor + $channel);
	  #$res = trb_strerror();
	  #print "error output: $res\n";
	  #print Dumper $rh_res;
	  push @hits ,$rh_res->{$dirich};
          #if ($_==1) {
            usleep(40E3);
          #}
        }

      my $diff = $hits[1] - $hits[0];
      #printf "channel: $channel: cur thresh: %.4x diff: $diff\n",$thresh ;
      #sleep 0.2;
      $hit_zero_diff_flag = 1 if($diff == 0);

      if($diff != 0 && !$hit_zero_diff_flag ) {
	  print "channel: $channel, backup threshold a bit (by 0x800)..., thresh: "; printf "0x%x\n",$thresh;
	  if($thresh <= $absolute_min_threshold) {
	      print "reached abs min threshold\n";
	      $boundaries->{$channel}->{'lower'} = $thresh;
	      last THRESH_LOOP;
	  }
	  else {
	      $thresh -= 0x800;
	      $lower_threshold -= 0x800;
	      $thresh_increment *= 4 if($thresh_increment <= 0x100);
	      next THRESH_LOOP;
	  }
      }

      $thresh_increment *= 4 if($thresh_increment <= 0x100 && $thresh >= $reasonable_upper_threshold );

      #my $thrstr = sprintf("0x%x", $thresh);
      #print "channel: $channel: thresh: $thrstr : diff: $diff, a=$hits[0] b=$hits[1]\n";

      my $thrstr = sprintf("0x%x", $thresh);
      if($diff >= 50) {
	  if( ! exists $boundaries->{$channel}->{'lower'} ) {
	      print "channel: $channel, lower thresh: $thrstr\n";
	      $boundaries->{$channel}->{'lower'} = $thresh;
	  }
      }
      elsif ($diff == 0 && exists $boundaries->{$channel}->{'lower'} && ($thresh - $boundaries->{$channel}->{'lower'} ) > 0x40  ) {
	  print "channel: $channel, upper thresh: $thrstr\n";
	  $boundaries->{$channel}->{'upper'} = $thresh;
	  last THRESH_LOOP;
      }

    } # THRESH_LOOP

    if ( ! exists $boundaries->{$channel}->{'upper'}) {
      $boundaries->{$channel}->{'upper'} = $upper_threshold;
      print "strange setting of upper thresh.\n";
    }

    $chain = ($channel <16) ? 0 : 1;
    #$command = $fixed_bits | ( (0x10|($channel&0xf)) << $channel_shift) | ($default_threshold << $shift_bits);
    $command = ($channel & 0xf)<<$REGNR | $WRITE | ($default_threshold&0xffff);
    Dmon::PadiwaSendCmd($command,$dirich, $chain);
    #trb_register_write($dirich, $throffset + $channel , $default_threshold);
}


printf "\nresult for 0x%.4x:\n",$dirich;
#print Dumper $boundaries;
print "channel | noiseband [mV]\n";
print "------------------------\n";
foreach my $cur_channel (sort {$a <=> $b} keys %$boundaries) {
    my $diff = $boundaries->{$cur_channel}->{upper} - $boundaries->{$cur_channel}->{lower};
    my $width = $diff * 38E-6 * 1000;
    printf "%2d      | %02.0f\n", $cur_channel , $width;
}

printf "\nsummary for 0x%.4x:\n", $dirich;
foreach my $cur_channel (sort {$a <=> $b} keys %$boundaries) {
    my $diff = $boundaries->{$cur_channel}->{upper} - $boundaries->{$cur_channel}->{lower};
    my $width = $diff * 38E-6 * 1000;
    printf "%02.0f ", $width;
}
print "\n";

