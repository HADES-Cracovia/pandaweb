#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use lib "/home/hadaq/trbsoft/daqtools/dmon/code";
use Dmon;

use Getopt::Long;
use Log::Log4perl qw(get_logger);

use HADES::TrbNet;

use IPC::ShareLite qw( :lock );

use constant false => 0;
use constant true => 1;

my $share = IPC::ShareLite->new(
    -key     => 3214,
    -create  => 'yes',
    -destroy => 'yes'
    ) or die $!;

$share->store("dummy text");
#print "store res: $r\n";

my $hitregister = 0xc001;

my @valid_interval = (0x8000, 0x9000);
my $interval_step = ($valid_interval[1] - $valid_interval[0])/2;
my $start_value = int ( ($valid_interval[1] + $valid_interval[0])/2 );

my $sleep_time = 1.0;
my $accepted_dark_rate = 150;
my $number_of_iterations = 40; # at least 15 are recommended

my $endpoint = 0x0303;
my $mode = "padiwa";
my $help = "";
my $offset = 0;
my $opt_skip = 99;
my $polarity = 1;
my @channels  = ();
my $channel32 = undef;
my $opt_finetune = false;

our $chain = 0;

my $result = GetOptions (
    "h|help" => \$help,
    "c|chain=i" => \$chain,
    "e|endpoint=s" => \$endpoint,
    "m|mode=s" => \$mode,
    "p|polarity=i" => \$polarity,
    "o|offset=s" => \$offset,
    "32|32channel" => \$channel32,
    "s|skip=i" => \$opt_skip,
    "f|finetune" => \$opt_finetune,
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
my @interval_step = ($interval_step) x 16;

if (defined $opt_skip && $opt_skip < 15) {
  $best_thresh[$opt_skip] = 0x7000;
}

if ($opt_finetune == true) {
    my $ra_thresh = read_thresholds("padiwa", $chain);
    @current_thresh = @$ra_thresh;
    print Dumper \@current_thresh;

    $interval_step = 4;

}

my $hit_diff = 0;

my $number_of_steps = 0;

my $rh_res;
my $old_rh_res;

while ($number_of_steps < $number_of_iterations ||
       grep({$_ == 0} @best_thresh) > 0
      ) {
  $number_of_steps++;
  last if($number_of_steps > 40);

  if ($mode eq "padiwa") {

    write_thresholds($mode, $chain, \@current_thresh);

    # wait settling time, experimentally determined to 0.04 seconds
    select(undef, undef, undef, 0.05);

    $old_rh_res = trb_register_read_mem($endpoint, $hitregister, 0, 32);

    select(undef, undef, undef, $sleep_time);

    $rh_res = trb_register_read_mem($endpoint, $hitregister, 0, 32);
    #print Dumper $rh_res;
    #print Dumper $old_rh_res;


    foreach my $i (0..15) {
       $interval_step = $interval_step[$i];

      my $cur_hitreg = $rh_res->{$endpoint}->[$i*$hitchannel_multiplicator];
      my $old_hitreg = $old_rh_res->{$endpoint}->[$i*$hitchannel_multiplicator] & 0x7fffffff;
      (my $hits, my $static_value) = ($cur_hitreg & 0x7fffffff , ($cur_hitreg & 0x80000000) >> 31);
      $hit_diff = abs($hits - $old_hitreg);
      $hit_diff[$i] = $hit_diff;

      if( ($static_value == ($polarity ? 0 : 1))
	  && $hit_diff < 100
	  && $crossed_thresh[$i] == 0) {
	$crossed_thresh[$i] = 1;
      }

#      $crossed_thresh[$i] = 1;

      # select best  threshold, closest from bottom
      if( 
	 #$crossed_thresh[$i] == 1 
	 $hit_diff[$i] <= $accepted_dark_rate
	 && $best_thresh[$i] <= $current_thresh[$i]
	 && $static_value == $polarity
	) {
	$best_thresh[$i] = $current_thresh[$i];
      }

      #delete bogus entries
      if($hit_diff[$i] >= $accepted_dark_rate && $current_thresh[$i] < $best_thresh[$i]) {
	$best_thresh[$i] = $current_thresh[$i];
      }

      my $direction = 1;
      if ( 
	  #$crossed_thresh[$i]==1 && 
	  $static_value == ($polarity ? 0 : 1)) {
	$interval_step = int($interval_step/1.2);
	$direction = -1;
      } elsif ($hit_diff > $accepted_dark_rate ) {
	$interval_step = int($interval_step/1.2);
	$direction = -1;
      } else {
	$interval_step = int($interval_step/1.2);
      }

      $interval_step = 2 if($interval_step < 2);
      $interval_step = 3 if($interval_step == 1 && $direction ==- 1);

      $interval_step[$i] = $interval_step;

      $current_thresh[$i] += $interval_step * $direction;

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


map { $_-= $offset } @best_thresh;
write_thresholds($mode, $chain, \@best_thresh);

my $uid;
foreach my $i (reverse (0..3)) {
  #print "send command: $endpoint , i: $i\n";
  $rh_res = Dmon::PadiwaSendCmd($endpoint, $chain, 0x10000000 | $i * 0x10000);
  $uid .= sprintf("%04x", $rh_res->{$endpoint} &0xffff);
  #print $uid;
}

my $str;
#$logger_data->info("thresholds have been set to the following values:");
#$logger_data->info(sprintf "endpoint: %04x, chain: %02d, uid: $uid", $endpoint, $chain);
foreach my $i (0..15) {
  $logger_data->info(sprintf "endpoint: 0x%04x, chain: %02d, channel: %2d threshold: 0x%04x, uid: %s", $endpoint, $chain, $i, $best_thresh[$i], $uid );
}


exit;


sub read_thresholds {
  (my $mode, my $chain) = @_;

  my @thresh = ();

  $share->store($chain);

  my $res = $share->lock(LOCK_EX);
  if(!defined $res || $res != 1) {
      die "could not lock shared element";
  }

#   my $rh_res = trb_register_write($endpoint,0xd410, 1 << $chain);

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
    my $rh_res = Dmon::PadiwaSendCmd($endpoint, $chain, $command);
    push (@thresh , $rh_res->{$endpoint});
  }

  #sleep 10 if($current_channel == 15 && $chain==1);
  #sleep 1;
  $share->unlock();


  return \@thresh;

}


sub write_thresholds {
  (my $mode, my $chain, my $ra_thresh) = @_;

  $share->store($chain);

  my $res = $share->lock(LOCK_EX);
  if(!defined $res || $res != 1) {
      die "could not lock shared element";
  }

  ### old and wrong way #my $rh_res = trb_register_write($endpoint,0xd410, 1 << $chain);

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

    $command = $fixed_bits | ($current_channel << 16) | ($ra_thresh->[$current_channel] << $shift_bits);
    Dmon::PadiwaSendCmd($endpoint, $chain, $command);


  }

  #sleep 10 if($current_channel == 15 && $chain==1);
  #sleep 1;
  $share->unlock();

}

sub send_command {
    (my $endpoint, my $chain, my $command) = @_;

    my $ra_atomic = [$command,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1<<$chain,0x10001];
    my $rh_res = trb_register_write_mem($endpoint, 0xd400, 0, $ra_atomic, scalar @{$ra_atomic});
    send_command_error($endpoint) if (!defined $rh_res);

    $rh_res = trb_register_read($endpoint,0xd412);
  #print Dumper $rh_res;
    send_command_error($endpoint) if (!defined $rh_res);
    return $rh_res;

}


sub send_command_old {
  (my $endpoint, my $command) = @_;

  my $rh_res = trb_register_write($endpoint,0xd400, $command);
  send_command_error($endpoint) if (!defined $rh_res);

  $rh_res = trb_register_write($endpoint,0xd411, 0x1);
  send_command_error($endpoint) if (!defined $rh_res);

  $rh_res = trb_register_read($endpoint,0xd412);
  #print Dumper $rh_res;
  send_command_error($endpoint) if (!defined $rh_res);
  return $rh_res;

}

sub send_command_error {
  my $res = trb_strerror();
  my $s= sprintf "error output for access to endpoint 0x%04x: $res\n", $endpoint;
  print $s;
  $s=~s/\n/, /g;
  $logger->error($s);
  $logger_data->error($s);
  exit();
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
