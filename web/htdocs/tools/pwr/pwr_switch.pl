#!/usr/bin/perl -w
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTP-?i/i) {
  &htsponse(200, "OK");
  }
print "Content-type: text/html\n\n";


use strict;
use warnings;
use Device::SerialPort;
use IO::Socket;
use feature 'state';
use URI::Escape;
use Time::HiRes qw( usleep);
use POSIX qw/floor ceil strftime/;

my $envstring = $ENV{'QUERY_STRING'};
$envstring =~ s/%20/ /g;
$envstring =~ s/Q/\?/g;


my @new_command = split('&',$envstring); 
my $ser_dev = shift(@new_command);
$ser_dev = "/dev/ttyUSB0" unless defined $ser_dev;

# my $ser_type = shift(@new_command);
# $ser_type = "PSP" unless defined $ser_type;
# 
# my $ser_speed = shift(@new_command);  #speed or port number
# $ser_speed = "2400" unless defined $ser_speed;


my $port;
# my $isIP = 0;
# my $isRemote = undef;
# 
# if($ser_dev =~ /^IP(.*)/) {
#   $ser_dev = $1;
#   $isIP = 1;
#   $port = IO::Socket::INET->new(PeerAddr => $ser_dev, PeerPort => $ser_speed, Proto => "tcp", Type => SOCK_STREAM) 
#               or die "ERROR: Cannot connect: $@";  
#   }
# elsif($ser_dev =~ /^SER(.*)/) {
#   my $str = $1;
#   ($isRemote,$ser_dev) = split('/',$str,2);
#   $ser_dev = '/'.$ser_dev;
#   }
# else {  
  $port = new Device::SerialPort($ser_dev);
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
#print "attempting to communicate with power supply connected to interface:\n$ser_dev\n\n";


# if(defined $isRemote) {
#   my $env = $ENV{'QUERY_STRING'};
# #   $env =~ s/%20/ /g;
#   $env =~ s/&/!/g;
#   my $cmd = "bash -c \"ssh $isRemote 'QUERY_STRING=".$env." perl'\" <htdocs/tools/pwr/pwr_remote.pl";
# #   system("ssh $isRemote 'QUERY_STRING=".$env." perl -v' ");
# #   print $cmd."\n";
#   print qx($cmd);
#   }
# else {
  print receive_answer();
#   }



sub Cmd {
  my ($c) = @_;
  for my $i (0..2) {
    $port->write($c."\n");
    my $a = "";
    for my $j (0..8) {
      my ($l,$s) = $port->read(5);
      $a .= $l;
      if ($l < 5) {next;}
      if ($s =~ /^\w[a-f0-9]{3}/) {return hex(substr($s,1,3)).'&';} 
      if ($s =~ /^\w[a-f0-9]{2}/) {return hex(substr($s,1,2)).'&';}
      usleep(10000);
      }
    usleep(50000);
    #print '.';
    }
  }




sub receive_answer {
  print strftime("%H:%M:%S &", localtime());
  my $ret ="";
#   print strftime("%H:%M:%S &", localtime());
  while ( my $command = shift(@new_command) ) {
    my $r = Cmd($command);
    print $r if($command =~ /\?/);
    }
  return $ret;
  }


  
print "\n";
  
exit 1;




