#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use Dmon;
use Getopt::Long;
use Time::HiRes qw(time usleep);
use Log::Log4perl qw(get_logger);
use List::Util qw(min max);
use POSIX qw(strftime);
use HADES::TrbNet;


my $hitregister = 0xc001;


my $sleep_time = 2.0;
my $accepted_dark_rate = 150;
my $number_of_iterations = 50;

my $endpoint = 0x0303;
my $mode = "padiwa";
my $help = "";
my $offset = 0;
my $polarity = 1;
my @channels  = ();
my $channel32 = undef;
my $opt_finetune = 0;

our $chain = 0;

my $result = GetOptions (
    "h|help" => \$help,
    "c|chain=i" => \$chain,
    "e|endpoint=s" => \$endpoint,
    "m|mode=s" => \$mode,
    "p|polarity=i" => \$polarity,
    "o|offset=s" => \$offset,
    "32|32channel" => \$channel32,
    "f|finetune" => \$opt_finetune,
    "l|sleep=f" => \$sleep_time,
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

my $interval_step = 0x0400;
my $start_value =  0x7000;
if ($polarity == -1) {$start_value = 0xb000;}


# go to the right position

my $hitchannel_multiplicator = 1;

if($channel32) {
    $hitregister += 32*$chain;
    $hitchannel_multiplicator = 2;
}
else {
    $hitregister += 16*$chain;
}

Log::Log4perl->init("logger_threshold.conf");

my $logger = get_logger("padiwa_threshold.log");
my $logger_data = get_logger("padiwa_threshold_data");


my $startup_str = sprintf "startup with: endpoint: $endpoint, chain: $chain, offset: $offset, polarity: $polarity";
$logger->info($startup_str);

trb_init_ports() or die trb_strerror();

my @current_thresh = ($start_value) x 16;
my @best_thresh = (0) x 16;
my @hit_diff = (0) x 16;
my @crossed_thresh = (0) x 16;

my @make_it_quiet;
my $rh_res;
my $old_rh_res;

if ($opt_finetune) {
  my $ra_thresh = read_thresholds("padiwa", $chain);
  @current_thresh = @$ra_thresh;
#   print Dumper \@current_thresh;
  $interval_step = 2;
  }

my @interval_step = ($interval_step) x 16;

#     foreach my $i (0..15) {

@make_it_quiet  = (0) x 16;
# $make_it_quiet[$i] = 0;
my $hit_diff = 0;

my $number_of_steps = 0;



while ($number_of_steps < $number_of_iterations) {
  $number_of_steps++;

  if ($mode eq "padiwa") {
    write_thresholds($mode, $chain, \@current_thresh);
    # wait settling time, experimentally determined to 0.04 seconds
    usleep(50000);
    $old_rh_res = trb_register_read_mem($endpoint, $hitregister, 0, 32);
    usleep($sleep_time*1E6);
    $rh_res = trb_register_read_mem($endpoint, $hitregister, 0, 32);


    foreach my $i (0..15) {
      $interval_step = $interval_step[$i];

      if ($make_it_quiet[$i]) {
        $make_it_quiet[$i] = 0;
        print STDERR "---\n";
        next;
        } 

      my $cur_hitreg = $rh_res->{$endpoint}->[$i*$hitchannel_multiplicator];
      my $old_hitreg = $old_rh_res->{$endpoint}->[$i*$hitchannel_multiplicator] & 0x00ffffff;
      (my $hits, my $static_value) = ($cur_hitreg & 0x00ffffff , ($cur_hitreg & 0x80000000) >> 31);
      $hit_diff = $hits - $old_hitreg;
      $hit_diff += 2**24 if $hit_diff < 0;
      $hit_diff[$i] = $hit_diff;

      if($number_of_steps  > $number_of_iterations - 20 || $opt_finetune) {
        # select best  threshold
        if(   $hit_diff[$i] <= $accepted_dark_rate
          && (   ($best_thresh[$i] <= $current_thresh[$i] && $polarity == 1) 
              || ($best_thresh[$i] >= $current_thresh[$i] && $polarity == -1)) 
          && $static_value == (($polarity==1)?0:1)) {
          $best_thresh[$i] = $current_thresh[$i];
          }

        #delete bogus entries
        if($hit_diff[$i] >= $accepted_dark_rate 
           && (   ($current_thresh[$i] < $best_thresh[$i] && $polarity == 1)
               || ($current_thresh[$i] > $best_thresh[$i] && $polarity == -1))) {
          $best_thresh[$i] = $current_thresh[$i];
          }
        }

      my $direction = 1;
      if ($static_value != (($polarity==1) ? 0 : 1)) {
        $current_thresh[$i] -= $interval_step * 2 * $polarity;
        $interval_step = int($interval_step/1.8)||1;
        } 
      elsif ($hit_diff > $accepted_dark_rate 
             && $hit_diff < 10000 ) {
        $current_thresh[$i] -= max($interval_step , $opt_finetune?0x2:0x10) * $polarity;
        $interval_step = max(int($interval_step/2),4);
        }
      elsif ($hit_diff > $accepted_dark_rate ) {
        $current_thresh[$i] -= max($interval_step * 2  , $opt_finetune?0x4:0x50)* $polarity;
        $interval_step = max(int($interval_step/2),0x10);
        if ($hit_diff > 20000) {
          $make_it_quiet[$i] = 1;
          }
        } 
      else {
        $current_thresh[$i] += $interval_step * $polarity;
        }
      
#       $interval_step = 8 if($interval_step < 8);
#       $interval_step = 50 if($interval_step <= 50 && $direction == -1);

      $interval_step[$i] = $interval_step;

#       $current_thresh[$i] += $interval_step * $direction;

      my $str = 
      sprintf ("iter: %4i, endpoint: 0x%04x, chain: %2d, channel: %2d, hits: %8d ",
               $number_of_steps,$endpoint, $chain, $i, $hits);
      $str.= "static: $static_value, diff: " .
        sprintf("%8d, dir: %2d", $hit_diff, $direction) . " , " .
          "new thresh: " . sprintf("0x%x", $current_thresh[$i]) .
            ", step_size: " . sprintf ("0x%04x best: 0x%04x", $interval_step[$i], $best_thresh[$i]);

      $logger->info($str);
      print STDERR $str."\n";
      } # end of loop over 15 channel

    } # end of if padiwa

  } #end of loop over steps


map { $_-= $offset } @best_thresh;
write_thresholds($mode, $chain, \@best_thresh);

my $uid;
foreach my $i (reverse (0..3)) {
  $rh_res = Dmon::PadiwaSendCmd(0x10000000 | $i * 0x10000, $endpoint, $chain);
  $uid .= sprintf("%04x", $rh_res->{$endpoint} &0xffff);
}

my $str;

$logger_data->info("\t".time);
foreach my $i (0..15) {
  $logger_data->info(sprintf "endpoint: 0x%04x, chain: %02d, channel: %2d threshold: 0x%04x, uid: %s", $endpoint, $chain, $i, $best_thresh[$i]||$current_thresh[$i], $uid );
}


exit;


sub read_thresholds {
  (my $mode, my $chain) = @_;

  my @thresh = ();

  foreach my $current_channel (0..15) {

    my $command;
    my $fixed_bits;
    my $shift_bits;

    if($mode eq "padiwa") {
      $fixed_bits = 0x00000000;
      $shift_bits = 0;
    }
    elsif ($mode eq "cbmrich") {
      die "readout of channels in cbmrich is not implemented";
      $fixed_bits = 0x00300000;
      $shift_bits = 4;
    }

    $command = $fixed_bits | ($current_channel << 16) ;
    my $rh_res = Dmon::PadiwaSendCmd($command, $endpoint, $chain, );
    push (@thresh , $rh_res->{$endpoint} & 0xFFFF);
  }



  return \@thresh;

}


sub write_thresholds {
  (my $mode, my $chain, my $ra_thresh) = @_;

  my @commands;
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
    my $thresh = $ra_thresh->[$current_channel];
    if($make_it_quiet[$current_channel]) {if($polarity == 1) {$thresh = 0x0000;} else {$thresh = 0xffff;}}
    push(@commands,$fixed_bits | ($current_channel << 16) | ($thresh << $shift_bits));
  }
  Dmon::PadiwaSendCmdMultiple(\@commands,$endpoint,$chain,5E3);
}

sub usage {

  print <<EOF;
usage: thresholds_automatic.pl --endpoint=<endpoint_address> --chain=<SPI-chain> [--offset=<number in decimal or hex>]
       [--help] [--mode=<"padiwa"|"cbmrich">] [--32channel]

example:

thresholds_automatic.pl --endpoint=0x303 --chain=0 --offset=0x10 --32channel
or in short
thresholds_automatic.pl -e 0x303 -o 0x10 -c 0

currently only mode "padiwa" is implemented.

polarity: tells what the status of bit 32 is, when the thresholds are set to 0
32channel: when set the tool assums a TDC with 32 channels, leading and trailing channels use two channels

EOF

}
