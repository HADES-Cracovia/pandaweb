#!/usr/bin/perl -w
use warnings;
use FileHandle;
use Time::HiRes qw( usleep );
use Data::Dumper;
use HADES::TrbNet;


if(!$ARGV[0]) {
  print "usage: dac_program.pl <filename of configuration file>  [offset]\n\n";
  print "The optional offset introduces an additional offset to the values read from the config file.\n";
  print "Example config file:\n";
  print "# Board   Chain     ChainLen    DAC     Channel       Command       Value\n";
  print "  f300    1         1           0       0             3             0x3456\n";
  print "  f300    1         1           0       1             3             12300\n";
  print "  f300    1         1           0       2             3             0xa123\n";
  print "!Reference 2500\n";
  print "  f300    1         1           0       3             3             1345 #=0x89ba\n";
  exit;
  }

if (!defined &trb_init_ports()) {
  die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
}

my $fh;
open $fh, "$ARGV[0]" or die $!."\nFile '$ARGV[0]' not found.";

my $offset = 0;
if (defined $ARGV[1]) {
  $offset = $ARGV[1];
  }

my $reference = 2**16;

while (my $a = <$fh>) {
  next if($a=~/^\s*#/);

  $a=~s/#.*//;
  if(my ($ref) = $a =~ /^\s*!Reference\s+(\w+)/i) {
    $ref = hex(substr($ref,2)) if (substr($ref,0,2) eq "0x");
    $reference = $ref * 1.;
#     print $reference."\n";
    }
 
  if(my ($board,$chain,$chainlen,$dac,$chan,$cmd,$val) = $a =~ /^\s*(\w\w\w\w)\s+(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\w)\s+(\w+)/) {
    $val   = hex(substr($val,2)) if (substr($val,0,2) eq "0x");
    $chain = hex(substr($chain,2)) if (substr($chain,0,2) eq "0x");
    $cmd   = hex($cmd);
    $board = hex($board);
    printf("0x%04x %i %i/%i %04x %i\n",$board,$chain,$dac,$chainlen,$val,$cmd);    
    if ($val+$offset >= $reference || $val+$offset < 0) {
      printf(STDERR "Error, value %i with offset %i is higher or lower than reference %i\n",$val,$offset,$reference);
      next;
      }
    
    $o = $cmd << 20;
    $o |= $chan << 16;
    $o |= (($val*1.+$offset)/$reference*65536.) & 0xFFFF;
    
    my @values;
    foreach my $i (0..15) {
      $values[$i] = 0x00F00000;
      }
    $values[16] = $chain;
    $values[17] = $chainlen;
    $values[$chainlen-1-$dac] = $o;
#    print Dumper @values;
#    print "\n";
    trb_register_write_mem($board,0xd400,0,\@values,18) or die "trb_register_write_mem: ", trb_strerror(); 
    usleep(5*$chainlen);
    }
  }
