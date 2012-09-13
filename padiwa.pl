#!/usr/bin/perl -w
use warnings;
use FileHandle;
use Time::HiRes qw( usleep );
use Data::Dumper;
use HADES::TrbNet;
use Date::Format;


if (!defined &trb_init_ports()) {
  die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
}
my $fh;

if(!$ARGV[0]) {
  print "usage: padiwa.pl \$FPGA \$chain \$command \$options\n\n";
  print "\t uid \t\t read unique ID, no options\n";
  print "\t temp \t\t read temperature, no options\n";
  print "\t pwm \t\t set PWM value. options: \$channel, \$value\n";
  print "\t pwm \t\t read PWM value. options: \$channel\n";
  print "\t disable \t set input diable. options: \$mask\n";
  print "\t disable \t read input disable. no options\n";
  print "\t input \t\t read input status. no options\n";
  print "\t invert \t\t set invert status. options: \$mask\n";
  print "\t invert \t\t read invert status. no options\n";
  print "\t led \t\t set led status. options: mask (5 bit, highest bit is override enable)\n";
  print "\t led \t\t read LED status. no options\n";
  print "\t monitor \t set input for monitor output. options: mask (4 bit)\n";
  print "\t monitor \t read monitor selection. no options\n";
  print "\t time \t\t read compile time. no options\n";
  exit;
  }
my $board, my $value, my $mask;
  
($board) = $ARGV[0] =~ /^0?x?(\w+)/;
$board = hex($board);

my $chain = hex($ARGV[1]);  

if (defined $ARGV[3]) {  
  ($mask) = $ARGV[3] =~ /^0?x?(\w+)/;
  $mask = hex($mask);
  }

if (defined $ARGV[4]) {  
  ($value) = $ARGV[4] =~ /^0?x?(\w+)/;
  $value = hex($value);
  }
    
  
  
  
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
  my $b = sendcmd(0x00800000+$ARGV[3]*0x10000+($value&0xffff));
  print "Wrote PWM settings.\n";
  }    
  
if($ARGV[2] eq "pwm") {
  my $b = sendcmd(0x00000000+$ARGV[3]*0x10000);
  foreach my $e (sort keys $b) {
    printf("0x%04x\t%d\t%d\t0x%04x\t%4.2f\n",$e,$chain,$ARGV[3],$b->{$e}&0xffff,($b->{$e}&0xffff)*3300/65536);
    }
  }  
  
  
if($ARGV[2] eq "disable" && defined $ARGV[3]) {
  my $b = sendcmd(0x20800000+($mask&0xffff));
  print "Wrote Input Disable settings.\n";
  }    
  
if($ARGV[2] eq "disable") {
  my $b = sendcmd(0x20000000);
  foreach my $e (sort keys $b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xffff);
    }
  }    

  
if($ARGV[2] eq "invert" && defined $ARGV[3]) {
  my $b = sendcmd(0x20840000+($mask&0xffff));
  print "Wrote Input Invert settings.\n";
  }    
  
if($ARGV[2] eq "invert") {
  my $b = sendcmd(0x20040000);
  foreach my $e (sort keys $b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xffff);
    }
  }    
  
  
if($ARGV[2] eq "input") {
  my $b = sendcmd(0x20010000);
  foreach my $e (sort keys $b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xffff);
    }
  }    

if($ARGV[2] eq "led" && defined $ARGV[3]) {
  my $b = sendcmd(0x20820000+($mask&0xffff));
  print "Wrote LED settings.\n";
  }    
  
if($ARGV[2] eq "led") {
  my $b = sendcmd(0x20020000);
  foreach my $e (sort keys $b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0x1f);
    }
  }     

  
if($ARGV[2] eq "monitor" && defined $ARGV[3]) {
  my $b = sendcmd(0x20830000+($mask&0xf));
  print "Wrote LED settings.\n";
  }    
  
if($ARGV[2] eq "monitor") {
  my $b = sendcmd(0x20030000);
  foreach my $e (sort keys $b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xf);
    }
  }     

if($ARGV[2] eq "time") {
  my $ids;
  for(my $i = 0; $i <= 1; $i++) {
    my $b = sendcmd(0x21000000 + $i*0x10000);
    foreach my $e (sort keys $b) {
      $ids->{$e}->{$i} = $b->{$e}&0xffff;
      }
    }
  foreach my $e (sort keys $ids) {
    printf("0x%04x\t%d\t0x%04x%04x\t%s\n",$e,$chain,$ids->{$e}->{1},$ids->{$e}->{0},time2str('%Y-%m-%d %H:%M',($ids->{$e}->{1}*2**16+$ids->{$e}->{0})));
    }
  } 
  