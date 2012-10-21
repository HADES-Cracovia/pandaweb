#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;


use Getopt::Long;
use Log::Log4perl qw(get_logger);

use HADES::TrbNet;

my $hitregister = 0xc001;

my @valid_interval = (0x3000, 0xa000);
my $interval_step = ($valid_interval[1] - $valid_interval[0])/2;
my $start_value = int ( ($valid_interval[1] + $valid_interval[0])/2 );



my $sleep_time = 0.1;
my $accepted_dark_rate = 4;
my $number_of_iterations = 1; # at least 15 are recommended

my $endpoint = 0x0303;
my $mode = "padiwa";
my $help = "";
my $offset = 0;
my @channels  = ();
our $chain = 0;

my $result = GetOptions (
    "h|help" => \$help,
    "c|chain=i" => \$chain,
    "e|endpoint=s" => \$endpoint,
    "m|mode=s" => \$mode,
    "o|offset=s" => \$offset,
    );

if($help) {
    usage();
    exit;
}


if ($offset) {
  if($offset =~ /^0x/) {
    $offset = hex($offset);
  }
  else {
    die "wrong number format for offset parameter: \"$offset\"" unless $offset =~ /^\d+$/;
    $offset = int($offset);
  }

  #print "called with offset: $offset\n";
}

die "wrong number format for chain parameter: \"$chain\"" unless $chain =~ /^\d+$/;

if($endpoint !~ /^0x/) {
    print "wrong format for enpoint number $endpoint, should be 0x0 - 0xffff, use hex notation with 0x\n";
    usage();
    exit;
}
$endpoint = hex($endpoint);


Log::Log4perl->init("logger_threshold.conf");

my $logger = get_logger("padiwa_threshold.log");
my $logger_data = get_logger("padiwa_threshold_data");

trb_init_ports() or die trb_strerror();

my @current_thresh = ($start_value) x 16;
my @best_thresh = (0) x 16;
my @hit_diff = (0) x 16;
my @crossed_thresh = (0) x 16;
my @interval_step = ($interval_step) x 16;

my $hit_diff = 0;

my $number_of_steps = 0;

my $rh_res;
my $old_rh_res;

#while (abs($interval_step) > 1 || $hit_diff > $accepted_dark_rate || $number_of_steps < 14) {

while ($number_of_steps < $number_of_iterations ||
#       grep({$_ > $accepted_dark_rate} @hit_diff) >0 ||
       grep({$_ == 0} @best_thresh) >0
      ) {
#while ($number_of_steps < 14 || grep({$_ > $accepted_dark_rate} @hit_diff) >0  ) {
#while ($number_of_steps < 14 ) {
  $number_of_steps++;
  last if($number_of_steps > 40);


  if ($mode eq "padiwa") {

    write_thresholds($mode, $chain, \@current_thresh);

    # wait settling time, experimentally determined to 0.04 seconds
    select(undef, undef, undef, 0.04);

    $old_rh_res = trb_register_read_mem($endpoint, $hitregister, 0, 16);

    select(undef, undef, undef, $sleep_time);

    $rh_res = trb_register_read_mem($endpoint, $hitregister, 0, 16);
    #print Dumper $rh_res;
    #print Dumper $old_rh_res;


    foreach my $i (0..15) {
      $interval_step = $interval_step[$i];

      my $cur_hitreg = $rh_res->{$endpoint}->[$i];
      my $old_hitreg = $old_rh_res->{$endpoint}->[$i] & 0x7fffffff;
      (my $hits, my $static_value) = ($cur_hitreg & 0x7fffffff , ($cur_hitreg & 0x80000000)>>31);
      $hit_diff = abs($hits - $old_hitreg);
      $hit_diff[$i] = $hit_diff;

      $crossed_thresh[$i] = 1 if($static_value == 0 && $hit_diff < 2);

      # select best  threshold, closest from bottom
      if($crossed_thresh[$i] == 1 && $hit_diff[$i] < $accepted_dark_rate &&
	 $best_thresh[$i] <= $current_thresh[$i] &&
	 $static_value == 1
	) {
	$best_thresh[$i] = $current_thresh[$i];
      }

      #delete bogus entries
      if($hit_diff[$i] >= $accepted_dark_rate && $current_thresh[$i] < $best_thresh[$i]) {
	$best_thresh[$i] = $current_thresh[$i];
      }

      my $direction = 1;
      if ($static_value == 0 && $hit_diff < 2) {
	$interval_step = int($interval_step/2 * 1.2);
	$direction = -1;
      } elsif ($hit_diff > $accepted_dark_rate ) {
	$interval_step = int($interval_step/2 * 1.2);
	$direction = -1;
      } else {
	$interval_step = int($interval_step/2);
      }

      $interval_step = 1 if($interval_step==0);
      $interval_step = 2 if($interval_step==1 && $direction==-1);

      $interval_step[$i] = $interval_step;

      $current_thresh[$i] += $interval_step * $direction;

      #$current_thresh += $interval_step * ($static_value ? 1 : -1.2);

      my $str = 
      sprintf ("iter: %4d, endpoint: 0x%04x, chain: %2d, channel: %2d, hits: %8d ",
	       $number_of_steps, $endpoint, $chain, $i, $hits);
      $str.= "static: $static_value, diff: " .
	sprintf("%8d, dir: %2d", $hit_diff, $direction) . " , " .
	  "new thresh: " . sprintf("0x%x", $current_thresh[$i]) .
	    ", step_size: " . sprintf ("0x%04x best: 0x%04x", $interval_step[$i], $best_thresh[$i]);

      $logger->info($str);

    } # end of loop over 15 channel

  } # end of if padiwa

} #end of loop over steps


map { $_-=$offset } @best_thresh;
write_thresholds($mode, $chain, \@best_thresh);

my $uid;
foreach my $i (reverse (0..3)) {
  #print "send command: $endpoint , i: $i\n";
  $rh_res = send_command($endpoint, 0x10000000 | $i * 0x10000);
  $uid .= sprintf("%04x", $rh_res->{$endpoint}&0xffff);
  #print $uid;
}

my $str;
#$logger_data->info("thresholds have been set to the following values:");
#$logger_data->info(sprintf "endpoint: %04x, chain: %02d, uid: $uid", $endpoint, $chain);
foreach my $i (0..15) {
  $logger_data->info(sprintf "endpoint: 0x%04x, chain: %02d, channel: %2d threshold: 0x%04x, uid: %s", $endpoint, $chain, $i, $best_thresh[$i], $uid );
}


exit;


sub write_thresholds {
  (my $mode, my $chain, my $ra_thresh) = @_;

  my $rh_res = trb_register_write($endpoint,0xd410, 1<<$chain);

  foreach my $current_channel (0..15) {

    my $command;
    my $fixed_bits;
    my $shift_bits;

    if($mode eq "padiwa") {
      $fixed_bits = 0x00800000;
      $shift_bits = 0;
    }
    elsif ($mode eq "cbmrich") {
      $fixed_bits = 0x00300000;
      $shift_bits = 4;
    }

    $command= $fixed_bits | ($current_channel<<16) | ($ra_thresh->[$current_channel] << $shift_bits);
    send_command($endpoint, $command);

  }
}


sub send_command {
  (my $endpoint, my $command) = @_;

  my $rh_res = trb_register_write($endpoint,0xd400, $command);
  send_command_error() if (!defined $rh_res);

  $rh_res = trb_register_write($endpoint,0xd411, 0x1);
  send_command_error() if (!defined $rh_res);

  $rh_res = trb_register_read($endpoint,0xd412);
  #print Dumper $rh_res;
  send_command_error() if (!defined $rh_res);
  return $rh_res;

}

sub send_command_error {
  my $res = trb_strerror();
  print "error output: $res\n";
  exit();
}

sub usage {

  print <<EOF;
usage: thresholds_automatic.pl --endpoint=<endpoint_address> --chain=<SPI-chain> [--offset=<number in decimal or hex>]
       [--help] [--mode=<"padiwa"|"cbmrich">]

example:

thresholds_automatic.pl l --endpoint=0x303 --chain=0 --offset=0x10
or in short
thresholds_automatic.pl -e 0x303 -o 0x10 -c 0

currently only mode "padiwa" is implemented.

EOF

}
