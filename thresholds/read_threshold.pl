#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;


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

my @valid_interval = (0x8000, 0x9000);
my $interval_step = ($valid_interval[1] - $valid_interval[0])/2;
my $start_value = int ( ($valid_interval[1] + $valid_interval[0])/2 );


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



Log::Log4perl->init("logger_threshold.conf");

my $logger = get_logger("padiwa_threshold_read.log");
my $logger_data = get_logger("padiwa_threshold_dump");


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


my $rh_res;
my $old_rh_res;

if ($mode eq "padiwa") {
    my $ra_thresh = read_thresholds("padiwa", $chain);
    @current_thresh = @$ra_thresh;

    @current_thresh = map { $_ & 0xffff } @current_thresh;

} # end of if padiwa


my $uid;
foreach my $i (reverse (0..3)) {
  #print "send command: $endpoint , i: $i\n";
  $rh_res = send_command($endpoint, 0x10000000 | $i * 0x10000);
  $uid .= sprintf("%04x", $rh_res->{$endpoint} &0xffff);
  #print $uid;
}

my $str;
#$logger_data->info("thresholds have been set to the following values:");
#$logger_data->info(sprintf "endpoint: %04x, chain: %02d, uid: $uid", $endpoint, $chain);
foreach my $i (0..15) {
  $logger_data->info(sprintf "endpoint: 0x%04x, chain: %02d, channel: %2d threshold: 0x%04x, uid: %s", $endpoint, $chain, $i, $current_thresh[$i], $uid );
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

  my $rh_res = trb_register_write($endpoint,0xd410, 1 << $chain);

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
    }

    my $rh_res = trb_register_write($endpoint,0xd410, 1 << $chain);
    $command = $fixed_bits | ($current_channel << 16) ;
    #my $rh_res = trb_register_write($endpoint,0xd410, 1 << $chain);
    $rh_res = send_command($endpoint, $command);
    #print Dumper $rh_res;
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


  my $rh_res = trb_register_write($endpoint,0xd410, 1 << $chain);

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
    send_command($endpoint, $command);


  }

  #sleep 10 if($current_channel == 15 && $chain==1);
  #sleep 1;
  $share->unlock();

}


sub send_command {
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
usage: read_threshold.pl --endpoint=<endpoint_address> --chain=<SPI-chain> 
    [--mode=<"padiwa"|"cbmrich">] [--32channel]

example:
read_threshold.pl --endpoint=0x303 --chain=0 --offset=0x10 --32channel
or in short
read_thresholds.pl -e 0x303 -o 0x10 -c 0

currently only mode "padiwa" is implemented.

polarity: tells what the status of bit 32 is, when the thresholds are set to 0
32channel: when set the tool assums a TDC with 32 channels, leading and trailing channels use two channels

EOF

}
