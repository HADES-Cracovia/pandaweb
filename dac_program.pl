#!/usr/bin/perl -w
use warnings;
use FileHandle;
use Time::HiRes qw( usleep );
use Data::Dumper;
use HADES::TrbNet;

if (!defined &trb_init_ports()) {
  die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
}
my $fh;

if(!$ARGV[0]) {
  print "usage: dac_program.pl <filename of configuration file>\n\n";
  print "Example config file:\n";
  print "# Board   ChainLen    DAC     Channel       Command       Value\n";
  print "  f300    1           0       0             3             0x3450\n";
  print "  f300    1           0       1             3             0x1230\n";
  print "  f300    1           0       2             3             0x6780\n";
  print "  f300    1           0       3             3             0x0345\n";
  exit;
  }

open $fh, "$ARGV[0]" or die $!."\nFile '$ARGV[0]' not found.";

while (my $a = <$fh>) {
  next if($a=~/^\s*#/);
  next if($a=~/^\s*\!/);

  $a=~s/#.*//;
  
 
  if(my ($board,$chain,$dac,$chan,$cmd,$val) = $a =~ /^\s*(\w\w\w\w)\s+(\d+)\s+(\d+)\s+(\d)\s+(\w)\s+(\w+)/) {
    if (substr($val,0,2) eq "0x") {
      $val = hex(substr($val,2));
      }
    $cmd = hex($cmd);
    $board = hex($board);
    
    $o = $cmd << 20;
    $o |= $chan << 16;
    $o |= $val;
    
    my @values;
    foreach my $i (0..($chain-1)) {
      $values[$i] = 0x00F00000;
      }
    $values[16] = $chain;
    $values[$chain-1-$dac] = $o;
#     print Dumper @values;
    trb_register_write_mem($board,0xd400,0,\@values,17) or die "trb_register_write_mem: ", trb_strerror(); 
    usleep(5*$chain);
    }
  }