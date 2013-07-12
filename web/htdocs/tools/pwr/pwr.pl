#!/usr/bin/perl -w
#print "Content-type: text/html\n\n";


use strict;
use warnings;
use Device::SerialPort;
use feature 'state';
use URI::Escape;
use Time::HiRes qw( usleep);

my $envstring = $ENV{'QUERY_STRING'};
$envstring =~ s/%20/ /g;


my @new_command = split('&',$envstring); 
my $ser_dev = shift(@new_command);
$ser_dev = "/dev/ttyUSB0" unless defined $ser_dev;

my $ser_type = shift(@new_command);
$ser_type = "PSP" unless defined $ser_type;

my $port = new Device::SerialPort($ser_dev);
unless ($port)
{
	print "can't open serial interface $ser_dev\n";
	exit;
}

$port->user_msg('ON'); 
$port->baudrate(2400) if $ser_type eq "PSP"; 
$port->baudrate(115200) if $ser_type eq "HMP"; 
$port->parity("none"); 
$port->databits(8); 
$port->stopbits(1); 
$port->handshake("xoff");
$port->handshake("none") if $ser_type eq "HMP"; 
$port->write_settings;

# debug output
#print "attempting to communicate with power supply connected to interface:\n$ser_dev\n\n";


transmit_command() if $ser_type eq "PSP"; #if new command, send it!
receive_answer() if $ser_type eq "PSP"; # always called


receive_answer_HMP() if $ser_type eq "HMP"; # always called

# transmit_command(); # send relais off in case current maximum is reached!
















sub transmit_command {

$port->lookclear; 

while ( my $command = shift(@new_command) ) {
    $command = uri_unescape($command);
    $port->write("$command\r\n");
    print "i sent the command: $command";
    #print "\n\nokay.\n";
    usleep 1E5;
  }
}




sub receive_answer {




	my %state_lookup = (
		0 => 'off',
		1 => 'on'	);

	my $found = 0;



	# clear buffers, then send the "list"-command to the power supply
	$port->lookclear; 
	$port->write("L\r");
	# sleep a second to give the supply time to react
	usleep 1E5;

	# read what has accumulated in the serial buffer
	while(my $a = $port->lookfor) {
		#print $a."\n"; # debug output
		if ($a =~ m/V(\d\d\.\d\d)A(\d\.\d\d\d)W(\d\d\d\.\d)U(\d\d)I(\d\.\d\d)P(\d\d\d)F(\d\d\d\d\d\d)/) {
			$found = 1;
			 my $c_volt = $1;
			 my $c_cur = $2;
			 my $c_pwr = $3;
			 my $l_volt = $4;
			 my $l_cur = $5;
			 my $l_pwr = $6;
			my $state_string = $7;
			 my $relais_state = $state_lookup{substr $state_string, 0,1};	
			printf("
			<table>
			<tr>
			<td align=right>%2.2f<td align=left> V
			<tr>
			<td align=right>%1.3f<td align=left> A
			<tr>
			<td align=right>%3.1f<td align=left> W
			<tr>
			<tr>
			<td align=right>voltage limit: %d<td align=left> V
			<tr>
			<td align=right>current limit: %1.2f<td align=left> A
			<tr>
			<td align=right>power limit: %d<td align=left> W
			<tr>
			<tr>
			<td align=right>output relais:<td align=left> $relais_state </td>
			</table>"
			,$c_volt,$c_cur,$c_pwr,$l_volt,$l_cur,$l_pwr);
	
# 			if( $c_cur > 0) {
# 				if($c_cur > ($l_cur * 0.9) ) { # check if current limit reached, if so, turn power off!
# 					print "!!! current limit reached, power off !!!<br>";
# 					push(@new_command,"KOD");
# 				}
# 			}
			
			last;
	
		}
	}
	}

sub receive_answer_HMP {

  while ( my $command = shift(@new_command) ) {
    $port->lookclear; 
    $command = uri_unescape($command);
    $port->write("$command\r\n");
#     print "i sent the command: $command\n";
    #print "\n\nokay.\n";
    usleep 1E5;
    while(my $a = $port->lookfor) {
      print $a."&"; # debug output
      }
    }
  }

print "\n";  
  
exit 1;
