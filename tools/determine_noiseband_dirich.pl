#!/usr/bin/perl
use warnings;
use strict;
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use Data::Dumper;

my $dirich = 0x1204;
my $throffset = 0xa000;
my $monitor = 0xdfc0;

my $last_channel = 5;

my $default_threshold = 0x3000;

#my $absolute_max_threshold = 0x8000;
my $absolute_min_threshold = 0x1000;

my @res; my $res; my $rh_res;

trb_init_ports() or die trb_strerror();

$res = trb_register_write($dirich, 0xdf80 , 0xffffffff);
if(!defined $res) {
    $res = trb_strerror();
    print "error output: $res\n";
}


for my $channel (0 .. 31) {
    trb_register_write($dirich, $throffset + $channel , $default_threshold);
    #$rh_res = trb_register_read($dirich, $throffset + $channel);
}

usleep (1E5);

my $boundaries = {};

for my $channel (0 .. $last_channel) {
#for my $channel (24 .. 27) {

    my $hit_zero_diff_flag = 0;

    my $lower_threshold = 0x6e00;
    my $upper_threshold = 0xd000;
    my $reasonable_upper_threshold = 0x8000;
    my $thresh_increment = 0x40;
    
  THRESH_LOOP:    for (my $thresh = $lower_threshold ; $thresh <= $upper_threshold; $thresh += $thresh_increment) {
      trb_register_write($dirich, $throffset + $channel , $thresh);
      undef $rh_res;
      my @hits = ();
      foreach (1..2) {
	  usleep(50E3);
	  $rh_res = trb_register_read($dirich, $monitor + $channel);
	  #$res = trb_strerror();
	  #print "error output: $res\n";
	  #print Dumper $rh_res;
	  push @hits ,$rh_res->{$dirich};
      }
      
      my $diff = $hits[1] - $hits[0];
      $hit_zero_diff_flag = 1 if($diff == 0);
      
      if($diff > 1 && !$hit_zero_diff_flag ) {
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
      if($diff > 1) {
	  if( ! exists $boundaries->{$channel}->{'lower'} ) {
	      print "channel: $channel, lower thresh: $thrstr\n";
	      $boundaries->{$channel}->{'lower'} = $thresh;
	  }
      }
      elsif ($diff == 0 && exists $boundaries->{$channel}->{'lower'}) {
	  print "channel: $channel, upper thresh: $thrstr\n";
	  $boundaries->{$channel}->{'upper'} = $thresh;
	  last THRESH_LOOP;
      }
      
  }
    if ( ! exists $boundaries->{$channel}->{'upper'}) {
	$boundaries->{$channel}->{'upper'} = $upper_threshold;
    }
    
    trb_register_write($dirich, $throffset + $channel , $default_threshold);
}


print "\nresult:\n";
#print Dumper $boundaries;
print "channel | noiseband [mV]\n";
print "------------------------\n";
foreach my $cur_channel (sort {$a <=> $b} keys %$boundaries) {
    my $diff = $boundaries->{$cur_channel}->{upper} - $boundaries->{$cur_channel}->{lower};
    my $width = $diff * 38E-6 * 1000;
    printf "%2d      | %02.0f\n", $cur_channel , $width;
}

print "\nsummary:\n";
foreach my $cur_channel (sort {$a <=> $b} keys %$boundaries) {
    my $diff = $boundaries->{$cur_channel}->{upper} - $boundaries->{$cur_channel}->{lower};
    my $width = $diff * 38E-6 * 1000;
    printf "%2d ", $width;
}
print "\n";
	

