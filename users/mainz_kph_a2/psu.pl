#!/usr/bin/perl
use strict;
use warnings;

use Device::SerialPort;

&main;

sub main {
  my $port = setup_connection("/dev/ttyACM0");
  my($U0,$I0,$OnOff0,$U0s,$I0s)=get_current_values($port, 0);
  my($U1,$I1,$OnOff1,$U1s,$I1s)=get_current_values($port, 1);
  printf("Output 0: %s %06.3fV (%06.3fV) %05.3fA (%05.3fA)\n", $OnOff0 ? "On" : "OFF" ,
         $U0, $U0s, $I0, $I0s);
  printf("Output 1: %s %06.3fV (%06.3fV) %05.3fA (%05.3fA)\n", $OnOff1 ? "On" : "OFF" ,
         $U1, $U1s, $I1, $I1s);
  $port->close or die "failed to close port";
}

sub get_current_values {
  my $port = shift;
  my $ch = shift;

  my $response = send_and_read($port,"750047",$ch);
  my($status1,$status2,$U,$I,$checksum) = unpack("x3CCnnn", $response);
  my $response_set = send_and_read($port,"750048",$ch);
  my($Uset,$Iset) = unpack("x5nnx", $response_set);

  # do the weird calculation to physical values (depends on device)
  $U = 84 * $U / 25600;
  $I = 5 * $I / 25600;
  my $OnOff = $status2 & 0x1;
  $Uset = 84 * $Uset / 25600;
  $Iset = 5 * $Iset / 25600;
  return ($U, $I, $OnOff, $Uset, $Iset);
}

sub send_and_read {
  my $port = shift;
  my $msg = shift; # msg bytes as hex coded string (without checksum)
  my $channel = shift || 0; # output 0 or 1?

  my @msg_int = map { hex($_) } ($msg =~ /(\w\w)/g);
  $msg_int[1] += $channel;

  my $msg_bytes = join('', map { pack('C',$_) } @msg_int);
  $msg_bytes .= pack('n', unpack('%16C*', $msg_bytes));
  #print "Sending ",unpack('H*', $msg_bytes), "\n";
  $port->write($msg_bytes) or die "Write failed";
  # read response
  my ($count,$saw)=$port->read(255); # will read _up to_ 255 chars
  #print "Got $count bytes: ", unpack('H*', $saw), "\n";
  return $saw;
}

sub setup_connection {
  my $portname = shift;
  my $port = Device::SerialPort->new($portname)
    or die "Can't connect to $portname: $!";

  # connection settings from ps2000b_programming.pdf
  $port->baudrate(115200);
  $port->databits(8);
  $port->parity("odd");
  $port->stopbits(1);
  $port->write_settings or die "Can't write settings";
  $port->read_char_time(0);     # don't wait for each character
  $port->read_const_time(100); # 1 second per unfulfilled "read" call

  return $port;
}
