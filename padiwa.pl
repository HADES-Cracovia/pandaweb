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
  print "usage: padiwa.pl \$FPGA \$chain \$command \$options\n\n";
  print "\t uid \t\t reads unique ID, no options\n";
  print "\t temp \t\t reads temperature, no options\n";
  print "\t pwm \t\t set PWM value. options: \$channel, \$value\n";
  print "\t pwm \t\t read PWM value. options: \$channel\n";
  exit;
  }
my $board, my $value;
  
($board) = $ARGV[0] =~ /^0?x?(\w+)/;
$board = hex($board);

if (defined $ARGV[4]) {  
  ($value) = $ARGV[4] =~ /^0?x?(\w+)/;
  $value = hex($value);
  }
    
  
# my $board = hex($ARGV[0]);  
my $chain = hex($ARGV[1]);  
  
  
sub sendcmd {
  my ($cmd) = @_;
  trb_register_write($board,0xd400,$cmd);
  trb_register_write($board,0xd411,1);
  return trb_register_read($board,0xd412);
  }
  
  


trb_register_write($board,0xd410,1<<$chain) or die "trb_register_write: ", trb_strerror(); 
  
if($ARGV[2] eq "temp") {
  my $b = sendcmd(0x10040000);
  foreach my $e (sort keys $b) {
    printf("0x%04x\t%d\t%2.1f\n",$e,$chain,($b->{$e}&0xfff)/16);
    }
  }

if($ARGV[2] eq "uid") {
  my $ids;
  for(my $i = 0; $i <= 3; $i++) {
    my $b = sendcmd(0x10000000 + $i*0x10000);
    foreach my $e (sort keys $b) {
      $ids->{$e}->{$i} = $b->{$e}&0xffff;
      }
    }
  foreach my $e (sort keys $ids) {
    printf("0x%04x\t%d\t0x%04x%04x%04x%04x\n",$e,$chain,$ids->{$e}->{3},$ids->{$e}->{2},$ids->{$e}->{1},$ids->{$e}->{0});
    }
  }
  
if($ARGV[2] eq "pwm" && defined $ARGV[4]) {
  my $b = sendcmd(0x00800000+$ARGV[3]*0x10000+(hex($ARGV[4])&0xffff));
  }    
  
if($ARGV[2] eq "pwm") {
  my $b = sendcmd(0x00000000+$ARGV[3]*0x10000);
  foreach my $e (sort keys $b) {
    printf("0x%04x\t%d\t%d\t0x%04x\t%4.2f\n",$e,$chain,$ARGV[3],$b->{$e}&0xffff,($b->{$e}&0xffff)*3300/65536);
    }
  }  