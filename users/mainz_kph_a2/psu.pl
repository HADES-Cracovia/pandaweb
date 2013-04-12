#!/usr/bin/perl
use strict;
use warnings;
use Device::SerialPort;

my($port,$maxU,$maxI);

&main;

sub main {
  setup_connection("/dev/ttyACM0");
  print_current_values(0);
  print_current_values(1);
  if(defined $ARGV[0] and $ARGV[0] eq "powercycle") {
    die "No Channel given to powercycle" unless defined $ARGV[1];
    my $channel = $ARGV[1] eq "1" ? 1 : 0;
    do_power_cycle($channel);
  }
  # serial connection is closed in END {} block
}

sub do_power_cycle {
  my $ch = shift;
  print "Powercycling Output $ch...\n";
  # enable remote control
  send_and_read("F100361010",$ch);

  # turn output off
  print "Turning off Output $ch...\n";
  send_and_read("F100360100",$ch);

  # wait until voltage is low enough (<1V)
  my $timeout = 100;
  while(1) {
    my $U = print_current_values($ch);
    last if $U<1 or $timeout==0;
    $timeout--;
  }

  if($timeout>0) {
    print "Waiting a bit more...\n";
    sleep(3);
    print_current_values($ch);
    print "Turning on Output $ch again...\n";
    send_and_read("F100360101",$ch);
    sleep(1);
  }
  else {
    print "Could not reach Voltage < 1 V before timeout.\n";
  }

  # disable remote control and print state again
  send_and_read("F100361000",$ch);
  print_current_values($ch);
}

sub print_current_values {
  my $ch = shift;
  my($U,$I,$OnOff,$Us,$Is,$R)=get_current_values($ch);
  printf("Output %d: %s, %06.3f V (-> %06.3f V), %05.3f A (-> %05.3f A) %d\n",
         $ch,
         $OnOff ? "On" : "OFF" ,
         $U, $Us, $I, $Is, $R);
  return $U;
}

sub get_current_values {
  my $ch = shift;

  my $response = send_and_read("750047",$ch);
  my($status1,$status2,$U,$I,$checksum) = unpack("x3CCnnn", $response);
  my $response_set = send_and_read("750048",$ch);
  my($Uset,$Iset) = unpack("x5nnx", $response_set);

  # do the weird calculation to physical values (depends on device)
  $U = $maxU * $U / 25600;
  $I = $maxI * $I / 25600;
  my $OnOff = $status2 & 0b1;
  my $Remote = $status1 &0b11;
  $Uset = $maxU * $Uset / 25600;
  $Iset = $maxI * $Iset / 25600;
  return ($U, $I, $OnOff, $Uset, $Iset, $Remote);
}

sub send_and_read {
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
  $port = Device::SerialPort->new($portname)
    or die "Can't connect to $portname: $!";

  # connection settings from ps2000b_programming.pdf
  $port->baudrate(115200);
  $port->databits(8);
  $port->parity("odd");
  $port->stopbits(1);
  $port->write_settings or die "Can't write settings";
  $port->read_char_time(0);     # don't wait for each character
  $port->read_const_time(100); # 100 ms per unfulfilled "read" call

  # Let's get the device identifier and deduce maximum voltage/current
  my $str = unpack("x3Z*", send_and_read("750000"));
  if(defined $str && $str =~/^PS \d(\d)(\d\d)-(\d\d)\w$/) {
    die "Single not implemented" if $1 != 3;
    $maxU = $2;
    $maxI = $3;
    printf("Device %s found: %d V, %d A maximum\n",$str,$maxU,$maxI); 
  }
  else {
    die "Device $str not recognized";
  }
}

END {
  if(defined $port) {
    # only warn here, since we're exiting anyway
    $port->close or warn "Failed to close port";
  }
}
