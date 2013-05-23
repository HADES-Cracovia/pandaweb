#!/usr/bin/perl -w
use warnings;
use FileHandle;
use Time::HiRes qw( usleep );
use Data::Dumper;
use HADES::TrbNet;
use Date::Format;

if(!defined $ENV{'DAQOPSERVER'}) {
  die "DAQOPSERVER not set in environment";
}
  
if (!defined &trb_init_ports()) {
  die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
}


if(!(defined $ARGV[0]) || !(defined $ARGV[1]) || !(defined $ARGV[2])) {
  print "usage: padiwa.pl \$FPGA \$chain \$command \$options\n\n";
  print "\t uid \t\t read unique ID, no options\n";
  print "\t time \t\t read compile time. no options\n";
  print "\t temp \t\t read temperature, no options\n";
  print "\t resettemp \t resets the 1-wire logic\n";
  print "\t dac \t\t set LTC-DAC value. options: \$channel, \$value\n";
  print "\t pwm \t\t set PWM value. options: \$channel, \$value\n";
  print "\t  \t\t read PWM value. options: \$channel\n";
  print "\t disable \t set input diable. options: \$mask\n";
  print "\t \t\t read input disable. no options\n";
  print "\t input \t\t read input status. no options\n";
  print "\t invert \t set invert status. options: \$mask\n";
  print "\t  \t\t read invert status. no options\n";
  print "\t led \t\t set led status. options: mask (5 bit, highest bit is override enable)\n";
  print "\t  \t\t read LED status. no options\n";
  print "\t monitor \t set input for monitor output. options: mask (4 bit). \n\t\t\t 0x10: OR of all channels, 0x18: or of all channels, extended to  16ns\n";
  print "\t  \t\t read monitor selection. no options\n";
  print "\t stretch \t set stretcher status.\n";
  print "\t  \t\t read stretcher status. no options\n";
  print "\t ram \t\t writes the RAM content, options: 16 byte in hex notation, separated by space, no 0x.\n";
  print "\t  \t\t read the RAM content (16 Byte)\n";
  print "\t flash \t\t execute flash command, options: \$command, \$page. See manual for commands.\n";
  print "\t enablecfg\t enable or disable access to configuration flash, options: 1/0\n";
  print "\t dumpcfg \t Dump content of configuration flash. Pipe output to file\n";
  print "\t writecfg \t Write content of configuration flash. options: \$filename\n";
  
  exit;
  }
my $board, my $value, my $mask;
  
($board) = $ARGV[0] =~ /^0?x?(\w+)/;
$board = hex($board);

my $chain = hex($ARGV[1]);  

if (defined $ARGV[3] && $ARGV[2] ne "writecfg") {  
  ($mask) = $ARGV[3] =~ /^0?x?(\w+)/;
  $mask = hex($mask) if defined $mask;
  }

if (defined $ARGV[4]) {  
  ($value) = $ARGV[4] =~ /^0?x?(\w+)/;
  $value = hex($value);
  }
    
  
sub sendcmd16 {
  my @cmd = @_;
  my $c = [@cmd,1<<$chain,16+0x80];
#   print Dumper $c;
  trb_register_write_mem($board,0xd400,0,$c,scalar @{$c});
  usleep(1000);
  }  
  
sub sendcmd {
  my ($cmd) = @_;
  my $c = [$cmd,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1<<$chain,1];
  trb_register_write_mem($board,0xd400,0,$c,scalar @{$c});
#   trb_register_write($board,0xd410,1<<$chain) or die "trb_register_write: ", trb_strerror();   
#   trb_register_write($board,0xd411,1);
  usleep(1000);
  return trb_register_read($board,0xd412);
  }
  
  

  
if($ARGV[2] eq "temp") {
  my $b = sendcmd(0x10040000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t%2.1f\n",$e,$chain,($b->{$e}&0xfff)/16);
    }
  }

if($ARGV[2] eq "resettemp") {
  sendcmd(0x10800001);
  usleep(100000);
  sendcmd(0x10800001);
  }

  
  
if($ARGV[2] eq "uid") {
  my $ids;
  for(my $i = 0; $i <= 3; $i++) {
    my $b = sendcmd(0x10000000 + $i*0x10000);
    foreach my $e (sort keys %$b) {
      $ids->{$e}->{$i} = $b->{$e}&0xffff;
      }
    }
  foreach my $e (sort keys %$ids) {
    printf("0x%04x\t%d\t0x%04x%04x%04x%04x\n",$e,$chain,$ids->{$e}->{3},$ids->{$e}->{2},$ids->{$e}->{1},$ids->{$e}->{0});
    }
  }

if($ARGV[2] eq "dac" && defined $ARGV[4]) {
  my $b = sendcmd(0x00300000+$ARGV[3]*0x10000+($value&0xffff));
  print "Wrote PWM settings.\n";
  }     
  
if($ARGV[2] eq "pwm" && defined $ARGV[4]) {
  my $b = sendcmd(0x00800000+$ARGV[3]*0x10000+($value&0xffff));
  print "Wrote PWM settings.\n";
  }    
  
if($ARGV[2] eq "pwm") {
  my $b = sendcmd(0x00000000+$ARGV[3]*0x10000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t%d\t0x%04x\t%4.2f\n",$e,$chain,$ARGV[3],$b->{$e}&0xffff,($b->{$e}&0xffff)*3300/65536);
    }
  }  
  
  
if($ARGV[2] eq "disable" && defined $ARGV[3]) {
  my $b = sendcmd(0x20800000+($mask&0xffff));
  print "Wrote Input Disable settings.\n";
  }    
  
if($ARGV[2] eq "disable") {
  my $b = sendcmd(0x20000000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xffff);
    }
  }    

  
if($ARGV[2] eq "invert" && defined $ARGV[3]) {
  my $b = sendcmd(0x20840000+($mask&0xffff));
  print "Wrote Input Invert settings.\n";
  }    
  
if($ARGV[2] eq "invert") {
  my $b = sendcmd(0x20040000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xffff);
    }
  }    
  

if($ARGV[2] eq "stretch" && defined $ARGV[3]) {
  my $b = sendcmd(0x20850000+($mask&0xffff));
  print "Wrote Input Stretcher settings.\n";
  }    
  
if($ARGV[2] eq "stretch") {
  my $b = sendcmd(0x20050000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xffff);
    }
  }      
  
if($ARGV[2] eq "input") {
  my $b = sendcmd(0x20010000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xffff);
    }
  }    

if($ARGV[2] eq "led" && defined $ARGV[3]) {
  my $b = sendcmd(0x20820000+($mask&0xffff));
  print "Wrote LED settings.\n";
  }    
  
if($ARGV[2] eq "led") {
  my $b = sendcmd(0x20020000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0x1f);
    }
  }     

  
if($ARGV[2] eq "monitor" && defined $ARGV[3]) {
  my $b = sendcmd(0x20830000+($mask&0x1f));
  print "Wrote monitor settings.\n";
  }    
  
if($ARGV[2] eq "monitor") {
  my $b = sendcmd(0x20030000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0x1f);
    }
  }     

if($ARGV[2] eq "time") {
  my $ids;
  for(my $i = 0; $i <= 1; $i++) {
    my $b = sendcmd(0x21000000 + $i*0x10000);
    foreach my $e (sort keys %$b) {
      $ids->{$e}->{$i} = $b->{$e}&0xffff;
      }
    }
  foreach my $e (sort keys %$ids) {
    printf("0x%04x\t%d\t0x%04x%04x\t%s\n",$e,$chain,$ids->{$e}->{1},$ids->{$e}->{0},time2str('%Y-%m-%d %H:%M',($ids->{$e}->{1}*2**16+$ids->{$e}->{0})));
    }
  } 
  
if($ARGV[2] eq "ram" && defined $ARGV[18]) {
  my @a;
  for(my $i=0;$i<16;$i++) {
    push(@a,0x40800000+hex($ARGV[3+$i])+($i << 16));
    }
  sendcmd16(@a);
  printf("Wrote RAM\n");
  }

if($ARGV[2] eq "ram") {
  for(my $i=0;$i<16;$i++) {
    my $b = sendcmd(0x40000000 + ($i << 16));
    foreach my $e (sort keys %$b) {    
      printf(" %02x ",$b->{$e}&0xff);
      }
    }
  printf("\n");
  }
  
if($ARGV[2] eq "flash" && defined $ARGV[4]) {
  my $c = 0x50800000+(($mask&0xe)<< 12)+($value&0x1fff);
  my $b = sendcmd($c);
  printf("Sent command\n");
  }
  
if($ARGV[2] eq "dumpcfg") {   
  for(my $p = 0; $p<5760; $p++) {  #5758
    sendcmd(0x50800000 + $p);
    printf("0x%04x:\t",$p);
    for(my $i=0;$i<16;$i++) {
      my $b = sendcmd(0x40000000 + ($i << 16));
      foreach my $e (sort keys %$b) {    
        printf(" %02x ",$b->{$e}&0xff);
        }
      }
    printf("\n");
    printf(STDERR "\r%d / 5760",$p) if(!($p%10)); 
    }
  }

if($ARGV[2] eq "enablecfg" && defined $ARGV[3]) {
  my $c = 0x5C800000 + $ARGV[3];
  my $b = sendcmd($c);
  printf("Sent command.\n");
  }  
  
if($ARGV[2] eq "writecfg" && defined $ARGV[3]) {   
  open(INF,$ARGV[3]) or die "Couldn't read file : $!\n";
  my $p = 0;
  while(my $s = <INF>) {
    my @t = split(' ',$s);
    my @a;
    for(my $i=0;$i<16;$i++) {
      push(@a,0x40800000 + (hex($t[$i+1]) & 0xff) + ($i << 16));
      }
    sendcmd16(@a);
    sendcmd(0x50804000 + $p);
    $p++;
    printf(STDERR "\r%d / 5760",$p) if(!($p%10)); 
    }
  }  