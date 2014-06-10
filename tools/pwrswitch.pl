#!/usr/bin/perl
# if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
#   print "HTTP/1.0 200 OK\n";
#   print "Content-type: text/html\r\n\r\n";
#   }
# else {
#   use lib '..';
#   print "Content-type: text/html\n\n";
#   }

use strict;
use warnings;
use Device::SerialPort;
use feature 'state';
use URI::Escape;
use Data::Dumper;
use Time::HiRes qw( usleep);
use Getopt::Long;

my $help;
my $ser_dev;
Getopt::Long::Configure(qw(gnu_getopt));
GetOptions(
           'help|h' => \$help,
           'device|d=s' => \$ser_dev,
          ) ;

# my $envstring = $ENV{'QUERY_STRING'};
# 
# 
# my @new_command = split('&',$envstring); 
# my $ser_dev = shift(@new_command);

$ser_dev = "/dev/ttyUSB0" unless defined $ser_dev;

my $port = new Device::SerialPort($ser_dev);

sub Cmd {
  my ($c) = @_;
  for my $i (0..2) {
    $port->write($c."\n");
    my $a = "";
    for my $j (0..8) {
      my ($l,$s) = $port->read(5);
      $a .= $l;
      if ($l < 5) {next;}
      if ($s =~ /^\w[a-f0-9]{3}/) {return hex(substr($s,1,3));} 
      if ($s =~ /^\w[a-f0-9]{2}/) {return hex(substr($s,1,2));}
      usleep(10000);
      }
    usleep(50000);
    #print '.';
    }
  return ;

  }

if ($help || (defined $ARGV[0] && $ARGV[0] =~ /help/)) {
  print "powerswitch.pl [-d DEVICE] [CHANNEL [OPERATION [VALUE]]\n\n";
  print "CHANNEL:   Channel number, hex or decimal\n";
  print "OPERATION: 1 (on), 0 (off), / (toggle), L (set limit)\n";
  print "VALUE:     A 10 Bit value, 3 hex digits or decimal\n";
  exit;
  }


unless ($port)
{
  print "can't open serial interface $ser_dev\n";
  exit;
}

$port->user_msg('ON'); 
$port->baudrate(57600); 
$port->parity("none"); 
$port->databits(8); 
$port->stopbits(1); 
$port->handshake("none"); 
$port->read_char_time(0);
$port->read_const_time(50);
$port->write_settings;

# debug output

my $num;  
if (my $t = Cmd("SFF?")) {  
 $num = 0xff- $t;
 }
else {
  die "Can not access power switch\n";
  }

my $ch;

my $args = scalar @ARGV;

if($args >= 1) {
  $ch = $ARGV[0];
  if (substr($ch,0,2) eq "0x") {$ch = hex(substr($ch,2));}
  if ($ch >= $num) {
    die "This channel does not exist\n";
    }
  }

if($args >= 2) {
  my $act = $ARGV[1];
  print ("Channel $ch => $act\n");
  if($act eq 'L') {
    my $lim = $ARGV[2];
    if (substr($lim,0,2) eq "0x") {$lim = hex(substr($lim,2));}
    my $cmd = sprintf("L%02x%03x",$ch,$lim);
    Cmd($cmd);
    }
  else {
    unless ($act eq '/' || $act == 0 || $act == 1){
      die "Action must be 0,1 or /\n";
      }
    my $chx = sprintf("%02x",$ch);
    Cmd("S$chx$act");
    }
  }
  
if($args <= 1 || 1) {
  print " Ch\t Curr.\t AvgCur\t Limit\n";

  for my $i (0..$num-1) {
    next if ($args >= 1 && $ch != $i);
    my $n = sprintf("%02x",$i);

    my $s    = Cmd("S$n?");
    my $curr = Cmd("C$n?");
    my $avg  = Cmd("D$n?");
    my $lim  = Cmd("L$n?");

    if(($s & 0xf0) == 0xe0) {printf(" $n\tERR\t\t (%3i)\n",$lim&0x3FF);}
    if(($s & 0xff) == 0x00) {printf(" $n\t---   \t\t (%3i)\n",$lim&0x3FF);}
    if(($s & 0xff) == 0x01) {printf(" $n\t%3imA\t %3imA\t (%3i)\n",$curr,$avg,$lim&0x3FF);}
    }
  
  }
  
  
  
