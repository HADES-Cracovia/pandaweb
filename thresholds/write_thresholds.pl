#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Dmon;
use Getopt::Long;
use HADES::TrbNet;
use POSIX qw(strftime);

# use Time::HiRes qw(usleep nanosleep);
my $offset = 0;
my $help;

my $result = GetOptions (
    "h|help" => \$help,
    "o|offset=s" => \$offset,
    );

if($help) {
  usage();
  exit;
}

if ($offset) {
  my $sign = 1;
  if( $offset =~/^-/ ) {
    $offset =~ s/^-//;
    $sign = -1;
  }

  if($offset =~ /^0x/) {
    $offset = hex($offset) * $sign;
  }
  else {
    die "wrong number format for offset parameter: \"$offset\"" unless $offset =~ /^\d+$/;
    $offset = int($offset) * $sign;
  }

  #print "called with offset: $offset\n";
}


trb_init_ports() or die trb_strerror();


open(my $fh, "<$ARGV[0]" || die "could not open file '$ARGV[0]'");
my @f = <$fh>;


#Put Information to logfile and timestamp to billboard information
#chomp $f[0];
#system("echo \"".strftime("%Y-%m-%d %H:%M:%S",localtime()).'\t'.time.'\t'.
#              $offset.'\t'.$f[0]."\">>threshold_log.txt");
#my ($t) = $f[0] =~ /(\d{10})/;
#system("echo $t>thresh/billboard_timestamp");
#my $offsetV = (32768 + $offset) & 0xffff;;
#system("echo $offsetV > thresh/billboard_offset");


my $count=0;
foreach my $cl (@f) {
    (my $ep, my $chain, my $channel, my $thresh, my $uid) = 
	$cl =~ /endpoint:\s+(\w+), chain:\s+(\d+), channel:\s+(\d+) threshold:\s+(\w+), uid: (\w+)/;

    #print "cl: $cl";
    #print "$ep, my $chain, my $channel, my $thresh, my $uid\n";
    next if(!defined $ep || !defined $chain || !defined $channel || !defined $thresh || length($thresh) > 6);

    $ep = hex($ep);
    $chain = int($chain);
    $channel = int($channel);
    $thresh = hex($thresh);
 
    next if($thresh > 0xffff);

    $thresh -= $offset;
	 #MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
	 # usleep(100000);
    write_threshold("padiwa", $ep, $chain, $channel, $thresh);
    $count++;

}

print "wrote $count thresholds\n";

exit;


sub write_threshold {
  (my $mode, my $endpoint, my $chain, my $current_channel, my $thresh) = @_;

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

  my $command= $fixed_bits | ($current_channel << 16) | ($thresh << $shift_bits);

  Dmon::PadiwaSendCmd($command, $endpoint, $chain);
  #send_command($endpoint, $chain, $command);
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

sub send_command_error {
    my $endpoint = @_;
    my $res = trb_strerror();
    my $s= sprintf "error output for access to endpoint 0x%04x: $res\n", $endpoint;
    print $s;
    $s=~s/\n/, /g;
    #$logger->error($s);
    #$logger_data->error($s);
    exit();
}


sub usage {

  print <<EOF;
usage: write_thresholds.pl [--help] [offset=<offset in hex or decimal>] [--mode=<"padiwa"|"cbmrich">] <filename of threshold results>

example:

write_thresholds.pl --offset=0x10 padiwa_thresholds_results

offset:
increases the thresholds stored in file by the given number.

filename: 
has to be in the format of the output of the automatic threshold determination

currently only mode "padiwa" is implemented.

The script puts a timestamp of execution and the timestamp of the thresholds file to threshold_log.txt.
The script puts the timestamp of the threshold file to billboard_info.

EOF

}
