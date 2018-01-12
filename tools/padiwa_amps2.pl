#!/usr/bin/perl -w
use warnings;
use FileHandle;
use Time::HiRes qw( usleep );
use Data::Dumper;
use HADES::TrbNet;
use Date::Format;
use Dmon;
use Getopt::Long;

if (!defined $ENV{'DAQOPSERVER'}) {
  die "DAQOPSERVER not set in environment";
}

if (!defined &trb_init_ports()) {
  die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
}

my $help;

my $endpoint;
my $chain;
my $channel;
my $execute;
my $register;
my $data;
my $ref_voltage = 3300;

my $result = GetOptions (
                         "h|help" => \$help,
                         "c|chain=i" => \$chain,
                         "n|channel=i" => \$channel,
                         "e|endpoint=s" => \$endpoint,
                         "x|execute=s" => \$execute,
                         "r|register=s" => \$register,
                         "v|ref_voltage=s" => \$ref_voltage,
                         "d|data=s" => \$data,
                        );

sub conv_input_string_to_number {
  (my $val, my $par_name, my $format) = @_;

  #print $val . "\n";
  return if (! defined $val);
  if (defined $format and $format eq "hex") {
    if ($val !~ /^0x/) {
      print "wrong format for input value \"$par_name\" with \"$val\", should be 0x0 - 0xffff, use hex notation with 0x\n";
      usage();
      exit;
    }
  }

  if ($val) {
    if ($val =~ /^0x/) {
      $val =~ s/^0x//;
      $val = hex($val);
    } else {
      die "wrong number format for parameter \"$par_name\": \"$val\"" unless $val =~ /^\d+$/;
      $val = int($val);
    }
  }
  return $val;
}


sub usage {    
  print "usage: padiwa_amps2.pl <--endpoint|e=0xYYYY> <--chain|c=N> <--execute|x=command> [--register=number] [--data=number]

commands:
\t uid \t\t read unique ID, no options
\t time \t\t read compile time. no options
\t temp \t\t read temperature, no optionsy
\t resettemp \t resets the 1-wire logic
\t dac \t\t set LTC-DAC data. options: \$channel, \$data
\t pwm \t\t set PWM data. options: \$channel, \$data
\t comp \t\t set temperature compensation data. options: \$data
\t discdisable \t set input diable. options: \$mask
\t discharge \t Disables the discharge signal if set. options: \$mask
\t discoverride \t Set discharge signal if disabled. options: \$mask
\t dischighz \t Set discharge signal to highZ. options: \$mask
\t discdelayinvert \t Invert signal used for delay generation. options: \$mask
\t inputenable \t\t read inputenable register. If option \"data\" given: write input enable bits
\t             \t\t bits: 0: enable, 1: disable
\t counter\t input signal counter. options: \$channel
\t invert \t set invert status. options: \$mask
\t led \t\t set led status. options: mask (5 bit, highest bit is override enable)
\t  \t\t read LED status. no options
\t ledoff\t\t turn off LEDs: First reads firmware-version and according to that turns 
\t monitor \t set input for monitor output. options: mask (4 bit).
\t\t\t 0x10: OR of all channels, 0x18: or of all channels, extended to  16ns
\t stretch \t set stretcher status.
\t ram \t\t writes the RAM content, options: 16 byte in hex notation, separated by space, no 0x.
\t  \t\t read the RAM content (16 Byte)
\t flash \t\t execute flash command, options: \$command, \$page. See manual for commands.
\t enablecfg\t enable or disable access to configuration flash, options: 1/0
\t erasecfg\t erases the config flash 
\t dumpcfg \t Dump content of configuration flash. Pipe output to file
\t writecfg \t Write content of configuration flash. options: \$filename
\t fifo \t\t Read a byte from the test fifo (if present, no options)
\t writereg|wr \t\t Write to a register
\t readreg|rr \t\t Read a register
";
  exit;
}

if ($help || !defined $endpoint || !defined $chain || !defined $execute) {
  usage();
}

$endpoint = &conv_input_string_to_number($endpoint, "endpoint", "hex");
$chain    = &conv_input_string_to_number($chain, "chain");

$register = &conv_input_string_to_number($register, "register") if (defined $register);
#&conv_input_string_to_number(\$execute, "execute") if (defined $execute);
$channel  = &conv_input_string_to_number($channel, "channel") if (defined $channel);
$data     = &conv_input_string_to_number($data, "data") if (defined $data);

$ref_voltage = &conv_input_string_to_number($ref_voltage, "ref_voltage") if (defined $ref_voltage);

#print "execute: $execute\n";
#exit;


sub sendcmd16 {
  my @cmd = @_;
  my $c = [@cmd,1<<$chain,16+0x80];
  #   print Dumper $c;
  trb_register_write_mem($board,0xd400,0,$c,scalar @{$c});
  usleep(1000);
}

my $sendcmd_executed_once = 0;
sub sendcmd {
  my ($cmd) = @_;
  $sendcmd_executed_once = 1;
  #print "endpoint: $endpoint, chain: $chain\n";
  return Dmon::PadiwaSendCmd($cmd,$endpoint,$chain);
  #  my $c = [$cmd,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1<<$chain,1];
  #  trb_register_write_mem($board,0xd400,0,$c,scalar @{$c});
  #   trb_register_write($board,0xd410,1<<$chain) or die "trb_register_write: ", trb_strerror();   
  #   trb_register_write($board,0xd411,1);
  #  usleep(1000);
  #  return trb_register_read($board,0xd412);
}

sub flash_is_busy {
  sendcmd(0x50800000);
  my $b = sendcmd(0x40000000);
  return (($b->{$board} >> 15) & 0x1);
}

if ($execute eq "temp") {
  die("not implemented");
  my $b = sendcmd(0x10040000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t%2.1f\n",$e,$chain,($b->{$e}&0xfff)/16);
  }
}

if ($execute eq "resettemp") {
  die("not implemented");
  sendcmd(0x10800001);
  usleep(100000);
  sendcmd(0x10800000);
}


if ($execute eq "uid") {
  my $ids;
  for (my $i = 0; $i <= 3; $i++) {
    my $b = sendcmd( (0x10+$i)<<24 );
    #print "uid: send done\n";
    #exit;
    foreach my $e (sort keys %$b) {
      $ids->{$e}->{$i} = $b->{$e}&0xffff;
    }
  }
  foreach my $e (sort keys %$ids) {
    printf("0x%04x\t%d\t0x%04x%04x%04x%04x\n",
           $e, $chain, $ids->{$e}->{3}, $ids->{$e}->{2}, $ids->{$e}->{1}, $ids->{$e}->{0} );
  }
}

if ($execute eq "dac" && defined $ARGV[4]) {
  die("not implemented");
  my $b = sendcmd(0x00300000+$ARGV[3]*0x10000+($value&0xffff));
  print "Wrote PWM settings.\n";
}

if ($execute eq "pwm") {
  if(!defined $data) {
    my $b = sendcmd($channel << 24 | 0x0<<20);
    foreach my $e (sort keys %$b) {
      printf("endpoint: 0x%04x  chain: %d  channel: %d  raw: 0x%04x  voltage: %4.2f mV\n",
             $e, $chain, $channel, $b->{$e}&0xffff, ($b->{$e}&0xffff)*$ref_voltage/65536 );
    }

  }
  else {
    my $b = sendcmd($channel << 24 | 0x8<<20 | ($data&0xffff));
  }
}

if ($execute eq "comp" && defined $ARGV[3]) {
  die("not implemented");
  my $b = sendcmd(0x20860000+($mask&0xffff));
  print "Wrote Temperature Compensation settings.\n";
}

if ($execute eq "comp") {
  die("not implemented");
  my $b = sendcmd(0x20060000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xffff);
  }
}

if ($execute eq "discdisable" && defined $ARGV[3]) {
  die("not implemented");
  my $b = sendcmd(0x20870000+($mask&0x00ff));
  print "Wrote Discharge Disable settings.\n";
}

if ($execute eq "discdisable") {
  die("not implemented");
  my $b = sendcmd(0x20070000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xff);
  }
}

if ($execute eq "discoverride" && defined $ARGV[3]) {
  die("not implemented");
  my $b = sendcmd(0x20880000+($mask&0x00ff));
  print "Wrote Discharge Disable settings.\n";
}

if ($execute eq "discoverride") {
  die("not implemented");
  my $b = sendcmd(0x20080000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xff);
  }
}

if ($execute eq "dischighz" && defined $ARGV[3]) {
  die("not implemented");
  my $b = sendcmd(0x20890000+($mask&0x00ff));
  print "Wrote Discharge Disable settings.\n";
}

if ($execute eq "dischighz") {
  die("not implemented");
  my $b = sendcmd(0x20090000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xff);
  }
}


if ($execute eq "discdelayinvert" && defined $ARGV[3]) {
  die("not implemented");
  my $b = sendcmd(0x208a0000+($mask&0x00ff));
  print "Wrote Discharge Disable settings.\n";
}

if ($execute eq "discdelayinvert") {
  die("not implemented");
  my $b = sendcmd(0x200a0000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xff);
  }
}


if ($execute eq "disable" && defined $ARGV[3]) {
  die("not implemented");
  my $b = sendcmd(0x20800000+($mask&0xffff));
  print "Wrote Input Disable settings.\n";
}

if ($execute eq "disable") {
  die("not implemented");
  my $b = sendcmd(0x20000000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xffff);
  }
}


if ($execute eq "invert" && defined $ARGV[3]) {
  die("not implemented");
  my $b = sendcmd(0x20840000+($mask&0xffff));
  print "Wrote Input Invert settings.\n";
}

if ($execute eq "invert") {
  die("not implemented");
  my $b = sendcmd(0x20040000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xffff);
  }
}


if ($execute eq "stretch" && defined $ARGV[3]) {
  die("not implemented");
  my $b = sendcmd(0x20850000+($mask&0xffff));
  print "Wrote Input Stretcher settings.\n";
}

if ($execute eq "stretch") {
  die("not implemented");
  my $b = sendcmd(0x20050000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xffff);
  }
}

if ($execute eq "inputenable") {
  if(!defined $data) {
    my $b = sendcmd(0x20 << 24 | 0x0 << 20);
    foreach my $e (sort keys %$b) {
      printf("endpoint: 0x%04x  chain: %d  inputenable: 0x%04x\n",
             $e, $chain, $b->{$e}&0xffff);
    }
  }
  else {
    my $b = sendcmd(0x20 << 24 | 0x8 << 20 | ($data&0xffff) );
  }
}

if ($execute eq "inputstatus") {
  my $b = sendcmd(0x21 << 24 | 0x0 << 20);
  foreach my $e (sort keys %$b) {
    printf("endpoint: 0x%04x  chain: %d  inputstatus: 0x%04x\n",
           $e, $chain, $b->{$e}&0xffff);
  }
}

if ($execute eq "ledoff") {
  die("not implemented");
  my $ids;
  for (my $i = 0; $i <= 1; $i++) {
    my $b = sendcmd(0x21000000 + $i*0x10000);
    #print Dumper $b;
    $ids->{$board}->{$i} = $b->{$board}&0xffff;
  }

  my $unix_compile_time = $ids->{$board}->{1}*2**16+$ids->{$board}->{0};
  if ($unix_compile_time >= 0x546f1960) {
    $mask = 0x0;
  } else {
    $mask =0x10;
  }

  if (!defined &trb_init_ports()) {
    die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
  }

  my $b = sendcmd(0x20820000+($mask&0x1ff));
  printf "turned LEDs off with command 0x%02x after reading firmware version\n",$mask;
}


if ($execute eq "led" && defined $ARGV[3]) {
  die("not implemented");
  my $b = sendcmd(0x20820000+($mask&0x1ff));
  print "Wrote LED settings.\n";
}

if ($execute eq "led") {
  die("not implemented");
  my $b = sendcmd(0x20020000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0x1ff);
  }
}

if ($execute eq "counter" && defined $ARGV[3]) {
  die("not implemented");
  my $b = sendcmd(0x22000000+(($mask&0x1f)<< 16));
  my $c = sendcmd(0x23000000+(($mask&0x1f)<< 16));
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t%8x\n",$e,$chain,($b->{$e}&0xffff)+($c->{$e}&0xff)*2**16);
  }
}


if ($execute eq "monitor" && defined $ARGV[3]) {
  die("not implemented");
  my $b = sendcmd(0x20830000+($mask&0x1f));
  print "Wrote monitor settings.\n";
}

if ($execute eq "monitor") {
  die("not implemented");
  my $b = sendcmd(0x20030000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0x1f);
  }
}

if ($execute eq "readreg" || $execute eq "rr" ) {
  if (!defined $register) {
    print "for the command readreg an option --register|r is missing.\n";
    usage;
  }

  my $b = sendcmd($register<<24 | 0x0 << 20);
  foreach my $e (sort keys %$b) {
    printf("0x%x\n", ($b->{$e}) & 0xffff);
  }
}

if ($execute eq "writereg" | $execute eq "wr") {
  if (!defined $data) {
    print "for the command writereg an option --data|d is missing.\n";
    usage;
  }
  my $b = sendcmd($register << 24 | 0x8 << 20 | ($data & 0xffff) );
}

if ($execute eq "time") {
  my $ids;
  for (my $i = 0; $i <= 2; $i++) {
    my $b = sendcmd( (0x30+$i) << 24 );
    foreach my $e (sort keys %$b) {
      $ids->{$e}->{$i} = $b->{$e}&0xffff;
    }
  }
  foreach my $e (sort keys %$ids) {
    printf("endpoint: 0x%04x chain: %d version: 0x%02x raw: 0x%04x%04x\t%s\n", 
           $e, $chain, $ids->{$e}->{2}, $ids->{$e}->{1}, $ids->{$e}->{0}, 
           time2str('%Y-%m-%d %H:%M', ( ($ids->{$e}->{1})<<16  | ($ids->{$e}->{0}) )) );
  }
}

if ($execute eq "ram" && defined $ARGV[18]) {

  my @a;
  for (my $i=0;$i<16;$i++) {
    push(@a,0x40800000+hex($ARGV[3+$i])+($i << 16));
  }
  sendcmd16(@a);
  printf("Wrote RAM\n");
}

if ($execute eq "ram") {
  for (my $i=0;$i<16;$i++) {
    my $b = sendcmd(0x40000000 + ($i << 16));
    foreach my $e (sort keys %$b) {
      printf(" %02x ",$b->{$e}&0xff);
    }
  }
  printf("\n");
}

if ($execute eq "flash" && defined $ARGV[4]) {
  my $c = 0x50800000+(($mask&0xe)<< 12)+($value&0x1fff);
  my $b = sendcmd($c);
  printf("Sent command\n");
}

if ($execute eq "dumpcfg") {
  for (my $p = 0; $p<5760; $p++) { #5758
    sendcmd(0x50800000 + $p);
    printf("0x%04x:\t",$p);
    for (my $i=0;$i<16;$i++) {
      my $b = sendcmd(0x40000000 + ($i << 16));
      foreach my $e (sort keys %$b) {
        printf(" %02x ",$b->{$e}&0xff);
      }
    }
    printf("\n");
    printf(STDERR "\r%d / 5760",$p) if(!($p%10));
  }
}

if ($execute eq "enablecfg" && defined $ARGV[3]) {
  my $c = 0x5C800000 + $ARGV[3];
  my $b = sendcmd($c);
  printf("Sent command.\n");
}

if ($execute eq "erasecfg") {
  while (flash_is_busy()) {
    printf(" busy - try again\n");
    usleep(300000);
  }
  ;
  sendcmd(0x5080E000);
  printf("Sent Erase command.\n");
}

if ($execute eq "writecfg" && defined $ARGV[3]) {
  open(INF,$ARGV[3]) or die "Couldn't read file : $!\n";
  while (flash_is_busy()) {
    printf(" busy - try again\n");
    usleep(300000);
  }
  ;
  my $p = 0;
  while (my $s = <INF>) {
    my @t = split(' ',$s);
    my @a;
    for (my $i=0;$i<16;$i++) {
      if ($p eq 0x167e && $i eq 11) {
        # adds the magic 09 the last page of the config flash
        push(@a,0x40800000 + (0x09) + ($i << 16));
      } else {
        push(@a,0x40800000 + (hex($t[$i+1]) & 0xff) + ($i << 16));
      }
    }
    sendcmd16(@a);
    sendcmd(0x50804000 + $p);

    $p++;
    printf(STDERR "\r%d / 5760",$p) if(!($p%10));
  }
}

if ($execute eq "fifo" || $execute eq "ffarr") {
  my $b = sendcmd(0x200f0000);
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t%d\t0x%04x\n",$e,$chain,$b->{$e}&0xffff);
  }
}


if ($sendcmd_executed_once == 0) {
  # no command found
  usage();
}

