use strict;
use warnings;
use Device::SerialPort;

use feature 'state';
use URI::Escape;
use Time::HiRes qw( usleep);
use POSIX qw/floor ceil strftime/;

my $envstring = $ENV{'QUERY_STRING'};
# print $envstring;

(my $null,$envstring) = split('/',$envstring,2);
$envstring = '/'.$envstring;
$envstring =~ s/%20/ /g;
$envstring =~ s/Q/\?/g;

my @new_command = split('\+',$envstring); 
my $ser_dev = shift(@new_command);
$ser_dev = "/dev/ttyUSB0" unless defined $ser_dev;

# print $envstring;
# exit 1;

my  $port = new Device::SerialPort($ser_dev);
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
  
 print receive_answer();
 
 
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
  while ( my $command = shift(@new_command) ) {
    my $r = Cmd($command);
    print $r if($command =~ /\?/);
    }
  return $ret;
  }


  
print "\n";
  
exit 1;
