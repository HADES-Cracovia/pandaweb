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
my $execute="";
my $register;
my $data;
my $ref_voltage = 3300;
my $filename;
my $flashcmd;
my $flashaddress;
my $enablecfgflash;
my $dumpcfgflash;
my $erasecfgflash;
my $writecfgflash;
my $dumpuserflash;
my $writeuserflash;
my $rr;
my $wr;
my $range;
my $memtoflash;

my $time;

my $READ  = 0x0<<20; # bits to set for a read command
my $WRITE = 0x8<<20; # bits to set for a write command
my $REGNR = 24; # number of bits to shift for the register number

my $result = GetOptions (
                         "h|help"           => \$help,
                         "c|chain=i"        => \$chain,
                         "n|channel=i"      => \$channel,
                         "e|endpoint=s"     => \$endpoint,
                         "x|execute=s"      => \$execute,
                         "r|register=s"     => \$register,
                         "v|ref_voltage=s"  => \$ref_voltage,
                         "d|data=s"         => \$data,
                         "f|filename=s"     => \$filename,
                         "flashcmd=s"       => \$flashcmd,
                         "flashaddress=s"   => \$flashaddress,
                         "enablecfgflash=i" => \$enablecfgflash,
                         "dumpcfgflash"     => \$dumpcfgflash,
                         "erasecfgflash"    => \$erasecfgflash,
                         "writecfgflash"    => \$writecfgflash,
                         "dumpuserflash:s"  => \$dumpuserflash,
                         "writeuserflash:s" => \$writeuserflash,
                         "eraseuserflash"   => \$eraseuserflash,
                         "memtoflash=s"     => \$memtoflash,
                         "range=s"          => \$range,
                         "time"             => \$time,
                         "readreg|rr:s"     => \$rr,
                         "writereg|wr:s"    => \$wr
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
  print <<EOF;
usage: padiwa_amps2.pl <--endpoint|e=0xYYYY> <--chain|c=N> [--register=number] [--data=number]

examples: padiwa_amps2.pl -e 0x1212 -c 0 -x time                       # reads the compile time of 0x1212, chain 0
          padiwa_amps2.pl -e 0x1212 -c 0 -x pwm --channel=1            # reads the threshold setting of channel 1
          padiwa_amps2.pl -e=0x1212 -c=0 -x=inputenable --data=0xa55a  # disables some channels
          padiwa_amps2.pl --endpoint=0x1212 --chain=0 -x dischargedelayinvert -d 0xff # sets the dischargedelayinvert bits
          padiwa_amps2.pl --endpoint=0x1212 --chain=0 -x dischargedelayinvert         # reads the dischargedelayinvert register
          padiwa_amps2.pl -e 0x1212 -c 0 --enablecfgflash=1            # enables the access to the config-flash
          padiwa_amps2.pl --endpoint=0x1212 --chain=0 --dumpcfgflash > flash_dump.txt
          
          Some of the commands can also be used directly, i.e. '-rr=0x12' instead of '-x=rr -register=0x12'

commands:
 uid                    read unique ID, no options
 time                   read compile time. no options
 temp                   read temperature, no options
 resettemp              resets the 1-wire logic
 dac                    set LTC-DAC data. options: \$channel, \$data
 pwm                    set PWM data. options: \$channel, \$data
 compensation           read/set temperature compensation data. options: \$data
 dischargedisable       set input diable. options: \$data
 dischargeoverride      Set discharge signal if disabled. options: \$data
 dischargehighz         Set discharge signal to highZ. options: \$data
 dischargedelayinvert   Invert signal used for delay generation. options: \$data
 dischargedelayselect   options: \$data, 4 bits
 inputenable            read inputenable register. If option \"data\" given: write input enable bits
                        bits: 0: enable, 1: disable
 counter                input signal counter. options: \$channel
 invert                 set invert status. options: \$data
 led                    set led status. options: data (5 bit, highest bit is override enable)
                        read LED status. no options
 ledoff                 turn off LEDs: First reads firmware-version and according to that turns 
 monitor                set input for monitor output. options: data (4 bit).
                            0x10: OR of all channels, 0x18: or of all channels, extended to  16ns
 stretch                read/set stretcher status.
 ram                    writes the RAM content, options: 16 byte in hex notation, separated by space, no 0x.
                            read the RAM content (16 Byte)
 flash                  execute flash command, options: \$command, \$page. See manual for commands.
 enablecfgflash         enable or disable access to configuration flash, options: 1/0
 erasecfgflash          erases the config flash
 dumpcfgflash           Dump content of configuration flash. Pipe output to file
 writecfgflash          Write content of configuration flash. options: \$filename
 eraseuserflash         erases the user flash
 dumpuserflas           Dump content of user flash. Pipe output to file
 writecfgflash          Write content of user flash. options: \$filename
 memtoflash             Saves memory content in the flash so that it is restored after boot
                        options: -range , format like '0x00..0x0F,0x23'
 fifo                   Read a byte from the test fifo (if present, no options)
 writereg|wr            Write to a register
 readreg|rr             Read a register
EOF

  exit;
}

if ($help || !defined $endpoint || !defined $chain) {
  usage();
}

$endpoint       = &conv_input_string_to_number($endpoint,       "endpoint", "hex");
$chain          = &conv_input_string_to_number($chain,          "chain");
$register       = &conv_input_string_to_number($register,       "register")       if (defined $register);
$channel        = &conv_input_string_to_number($channel,        "channel")        if (defined $channel);
$data           = &conv_input_string_to_number($data,           "data")           if (defined $data);
$ref_voltage    = &conv_input_string_to_number($ref_voltage,    "ref_voltage")    if (defined $ref_voltage);
$flashcmd       = &conv_input_string_to_number($flashcmd,       "flashcmd")       if (defined $flashcmd);
$flashaddress   = &conv_input_string_to_number($flashaddress,   "flashaddress")   if (defined $flashaddress);
$enablecfgflash = &conv_input_string_to_number($enablecfgflash, "enablecfgflash") if (defined $enablecfgflash);
$rr             = &conv_input_string_to_number($rr,             "readreg")        if (defined $rr);
$wr             = &conv_input_string_to_number($wr,             "writereg")       if (defined $wr);


#print "execute: $execute\n";
#exit;


sub sendcmd16 {
  my @cmd = @_;
  my $c = [@cmd,1<<$chain,16+0x80];
  #   print Dumper $c;
  trb_register_write_mem($endpoint,0xd400,0,$c,scalar @{$c});
  usleep(1000);
}

my $sendcmd_executed_once = 0;
sub sendcmd {
  my ($cmd) = @_;
  $sendcmd_executed_once = 1;
  #printf("endpoint: 0x%x, chain: 0x%x, cmd: 0x%x\n", $endpoint, $chain, $cmd);
  return Dmon::PadiwaSendCmd($cmd,$endpoint,$chain);
}

sub flash_is_busy {
    my $b = sendcmd(0x5C<<$REGNR | $READ );
    return (($b->{$endpoint} >> 2) & 0x1);
}


sub check_std_io {
  (my $command, my $register) = @_;

  if ($execute eq $command) {
    if(!defined $data) {
      my $b = sendcmd($register<<$REGNR | $READ);
      foreach my $e (sort keys %$b) {
        printf("endpoint: 0x%04x  chain: %d  $command: 0x%04x\n",$e,$chain,$b->{$e}&0xffff);
      }
    }
    else {
      my $b = sendcmd($register<<$REGNR | $WRITE | ($data & 0xffff));
    }
  }
}

check_std_io("inputenable",          0x20);
check_std_io("inputstatus",          0x21);
check_std_io("led",                  0x22);
check_std_io("monitor",              0x23);
check_std_io("invert",               0x24);
check_std_io("stretch",              0x25);
check_std_io("compensation",         0x26);
check_std_io("dischargedisable",     0x27);
check_std_io("dischargeoverride",    0x28);
check_std_io("dischargehighz",       0x29);
check_std_io("dischargedelayinvert", 0x2a);
check_std_io("dischargedelayselect", 0x2b);


if ($execute eq "temp") {
    my $register=0x14;
    my $b = sendcmd($register<<$REGNR | $READ);
    foreach my $e (sort keys %$b) {
	printf("enpoint: 0x%04x  chain: %d  temp: %2.1f\n",$e,$chain,($b->{$e}&0xfff)/16);
    }
}

if ($execute eq "resettemp") {
  die("not implemented");
  sendcmd(0x10800001);
  usleep(100000);
  sendcmd(0x10800000);
}

if ($execute eq "uid" || defined $time) {
  my $ids;
  for (my $i = 0; $i <= 3; $i++) {
    my $b = sendcmd( (0x10+$i)<<$REGNR );
    foreach my $e (sort keys %$b) {
      $ids->{$e}->{$i} = $b->{$e}&0xffff;
    }
  }
  foreach my $e (sort keys %$ids) {
    printf("endpoint: 0x%04x  chain: %d  raw: 0x%04x%04x%04x%04x\n",
           $e, $chain, $ids->{$e}->{0}, $ids->{$e}->{1}, $ids->{$e}->{2}, $ids->{$e}->{3} );
  }
}

if ($execute eq "dac" && defined $ARGV[4]) {
  die("not implemented");
  #my $b = sendcmd(0x00300000+$ARGV[3]*0x10000+($value&0xffff));
  print "Wrote PWM settings.\n";
}

if ($execute eq "pwm") {
  die "the command pwm needs an --channel option." if (!defined $channel);
  if(!defined $data) {
    my $b = sendcmd($channel<<$REGNR | $READ);
    foreach my $e (sort keys %$b) {
      printf("endpoint: 0x%04x  chain: %d  channel: %d  raw: 0x%04x  voltage: %4.2f mV\n",
             $e, $chain, $channel, $b->{$e}&0xffff, ($b->{$e}&0xffff)*$ref_voltage/65536 );
    }

  }
  else {
    my $b = sendcmd($channel<<$REGNR | $WRITE | ($data&0xffff));
  }
}


if ($execute eq "ledoff") {
  my $b = sendcmd(0x22<<$REGNR | $WRITE | 0);
}

if ($execute eq "counter" && defined $ARGV[3]) {
  die("not implemented");
  my $b = sendcmd(0x22000000+(($mask&0x1f)<< 16));
  my $c = sendcmd(0x23000000+(($mask&0x1f)<< 16));
  foreach my $e (sort keys %$b) {
    printf("endpoint: 0x%04x  chain: %d  counter: %8x\n",$e,$chain,($b->{$e}&0xffff)+($c->{$e}&0xff)*2**16);
  }
}


if ($execute eq "readreg" || $execute eq "rr" || defined($rr)) {
  if (!defined $register && !defined $rr) {
    print "for the command readreg an option --register|r or --rr is missing.\n";
    exit;
  }
  if (!defined($register)) {$register=$rr;}
  my $b = sendcmd($register<<$REGNR | $READ);
  foreach my $e (sort keys %$b) {
    printf("0x%x\n", ($b->{$e}) & 0xffff);
  }
}

if ($execute eq "writereg" | $execute eq "wr" || defined($wr)) {
  if (!defined $register && !defined $wr) {
    print "for the command writereg an option --register|r or --wr is missing.\n";
    exit;
  }
  if (!defined($register)) {$register=$wr;}
  if (!defined $data) {
    print "for the command writereg an option --data|d is missing.\n";
    exit;
  }
  #print "write: "; printf "reg: %x, data: %x\n",$register, $data;
  my $b = sendcmd($register<<$REGNR | $WRITE | ($data & 0xffff) );
}

if ($execute eq "time") {
  my $ids;
  for (my $i = 0; $i <= 2; $i++) {
    my $b = sendcmd( (0x30+$i)<<$REGNR | $READ );
    foreach my $e (sort keys %$b) {
      $ids->{$e}->{$i} = $b->{$e}&0xffff;
    }
  }
  foreach my $e (sort keys %$ids) {
    printf("endpoint: 0x%04x  chain: %d  version: 0x%02x  raw: 0x%04x%04x  %s\n", 
           $e, $chain, $ids->{$e}->{2}, $ids->{$e}->{1}, $ids->{$e}->{0},
           time2str('%Y-%m-%d %H:%M', ( ($ids->{$e}->{1})<<16  | ($ids->{$e}->{0}) )) );
  }
}

if ($execute eq "ram" && defined $ARGV[18]) {
  die("not implemented");
  my @a;
  for (my $i=0;$i<16;$i++) {
    push(@a,0x40800000+hex($ARGV[3+$i])+($i << 16));
  }
  sendcmd16(@a);
  printf("Wrote RAM\n");
}

if ($execute eq "ram") {
  die("not implemented");
  for (my $i=0;$i<16;$i++) {
    my $b = sendcmd(0x40000000 + ($i << 16));
    foreach my $e (sort keys %$b) {
      printf(" %02x ",$b->{$e}&0xff);
    }
  }
  printf("\n");
}

###############################################################################

if (defined $flashcmd) {
    if (!defined $flashaddress) {
	$flashaddress=0;
    }
    #my $c = 0x50<<$REGNR | $WRITE | (($flashcmd&0xe)<< 12)  + ($flashaddress&0x1fff);
    my $b = sendcmd(0x5C<<$REGNR | $READ);
    sendcmd(0x5C<<$REGNR | $WRITE | ($b->{$endpoint}&0x1) | 0x100); ##new 16 bit scheme
    sendcmd(0x51<<$REGNR | $WRITE | $flashcmd&0xe); 
    sendcmd(0x50<<$REGNR | $WRITE | $flashaddress&0xffff);
    #printf("Sent flash command $flashcmd\n");
}

###############################################################################

sub enableccfgflash {
    sendcmd(0x5C<<$REGNR | $WRITE | 0x101);
}

sub enableuserflash {
    sendcmd(0x5C<<$REGNR | $WRITE | 0x100);
}

if ($execute eq "enableccfgflash" | defined $enablecfgflash) {
    die "--enableccfgflash can only be 0 or 1\n" unless ($enablecfgflash == 0 || $enablecfgflash == 1);
    if ($enablecfgflash eq 1) {
	enableccfgflash();
    } else {
	enableuserflash();
    }
    my $str = ($enablecfgflash) ? "enabled" : "disabled";
    printf("$str cfgflash.\n");
}

###############################################################################

if ($execute eq "dumpcfgflash" | defined $dumpcfgflash) {
    enableccfgflash();
    for (my $p = 0; $p<0x23ff; $p++) {
	sendcmd(0x51<<$REGNR | $WRITE | 0x0);
	sendcmd(0x50<<$REGNR | $WRITE | $p);      # read page $p
	printf("0x%04x:\t",$p);
	for (my $i=0;$i<16;$i++) {
	    my $b = sendcmd( (0x40+$i)<<$REGNR | $READ );
	    foreach my $e (sort keys %$b) {
		printf(" %02x ",$b->{$e}&0xff);
	    }
	}
	printf("\n");
	printf(STDERR "\r%d",$p) if(!($p%10));
    }
}

sub erasecfgflash {
    enableccfgflash();
    while (flash_is_busy()) {
	printf(" busy - try again\n");
	usleep(300000);
    }
    sendcmd(0x51<<$REGNR | $WRITE | 0xE);
    sendcmd(0x50<<$REGNR | $WRITE | 0x0);
    printf("Sent Erase command.\n");
}

if ($execute eq "erasecfgflash" | defined $erasecfgflash) {
    erasecfgflash();
}

if ($execute eq "writecfgflash" | defined $writecfgflash) {
    if (!defined($filename)) {$filename=$writecfgflash;}
    if (!defined $filename) {
        die "for the command writecfgflash an option or --filename is missing.\n";
    }
    if (length($filename)==0) {
        die "for the command writecfgflash an option or --filename is missing.\n";
    }
    open(INF, $filename) or die "Couldn't read file : $!\n";
    erasecfgflash();
    while (flash_is_busy()) {
	printf(" busy - try again\n");
	usleep(300000);
    }
    my $p = 0;
    while (my $s = <INF>) {
	my @t = split(' ',$s);
	my @a;
	for (my $i=0;$i<16;$i++) {
	    push(@a,0x40<<$REGNR | $i << $REGNR | $WRITE | (hex($t[$i+1]) & 0xff));
	}
	sendcmd16(@a);
	sendcmd(0x51<<$REGNR | $WRITE | 0x4);
	sendcmd(0x50<<$REGNR | $WRITE | $p);
	
	$p++;
	printf(STDERR "\r%d ",$p) if(!($p%10));
    }
    my @a;
    for (my $i=0;$i<16;$i++) {
	if ($i eq 11) {
	    # adds the magic 09 the last page of the config flash   
	    push(@a,0x40<<$REGNR | $i << $REGNR | $WRITE | 0x09);
	} else {
	    push(@a,0x40<<$REGNR | $i << $REGNR | $WRITE | 0x0);
	}
    }
    sendcmd16(@a);
    sendcmd(0x51<<$REGNR | $WRITE | 0x4);
    sendcmd(0x50<<$REGNR | $WRITE | 0x23fc);    
}

###############################################################################

sub eraseuserflash {
    enableuserflash();
    while (flash_is_busy()) {
	printf(" busy - try again\n");
	usleep(300000);
    }
    sendcmd(0x51<<$REGNR | $WRITE | 0xE);
    sendcmd(0x50<<$REGNR | $WRITE | 0x0);
    printf("Sent Erase command.\n");
    while (flash_is_busy()) {
        printf(" busy - try again\n");
        usleep(300000);
    }
}

if ($execute eq "eraseuserflash" | defined $eraseuserflash) {
    eraseuserflash();
}

if ($execute eq "writeuserflash" | defined $writeuserflash) {
    if (!defined($filename)) {$filename=$writeuserflash;}
    if (!defined $filename) {
	die "for the command writeuserflash an option or --filename is missing.\n";
	
    }
    if (length($filename)==0) {
        die "for the command writeuserflash an option or --filename is missing.\n";
    }
    eraseuserflash();
    open(INF, $filename) or die "Couldn't read file : $!\n";
    my $p;
    while (my $s = <INF>) {
	next unless($s =~ /^0x\w\w\w\w:/);
        my @t = split(' ',$s);
	#print "t:"; print Dumper \@t;
        my @a;
        for (my $i=0;$i<16;$i++) {
            push(@a,0x40<<$REGNR | $i << $REGNR | $WRITE | (hex($t[$i+1]) & 0xff));
        }
	#print "a: "; print Dumper \@a;
        sendcmd16(@a);
	$p = $t[0];
	if ($p =~ /^0x/) {
	    $p =~ s/[:]$//;
	    sendcmd(0x51<<$REGNR | $WRITE | 0x4);
	    sendcmd(0x50<<$REGNR | $WRITE | (hex($p) & 0xffff));
	}
    }
}

if ($execute eq "dumpuserflash" | defined $dumpuserflash) {
    if (!defined($range)) { 
	if (defined($dumpuserflash)) {
	    if(length($dumpuserflash)>0) {
		$range=$dumpuserflash;
	    } else {
		$range="0x1c00..0x1c0F"
	    }
	}
	if (!defined($dumpuserflash)) {$range="0x00..0x0F"}
    }

    enableuserflash();
    my @q = (eval $range);
    
    foreach my $p (@q) {
	#for (my $p = 0x1c00; $p < 0x1c10; $p++) {
	sendcmd(0x51<<$REGNR | $WRITE | 0x0);
	sendcmd(0x50<<$REGNR | $WRITE | $p);
        printf("0x%04x:\t",$p);
        for (my $i=0;$i<16;$i++) {
            my $b = sendcmd((0x40<<$REGNR) | ($i << $REGNR));
            foreach my $e (sort keys %$b) {
                printf(" %02x ",$b->{$e}&0xff);
            }
        }
        printf("\n");
    }
}

if ($execute eq "memtoflash" || defined($memtoflash)) {
    if (!defined $range && !defined $memtoflash) {
	print "for the command memtoflash an option --range is missing.\n";
	exit;
    }
    if (!defined($range)) {$range=$memtoflash;}
    eraseuserflash();
    my @q = (eval $range); 
    my $max  = scalar(@q);
    my $page = 0x0;
    my $c = 0;
    my @a;
    for (my $i=0;$i<$max;$i++) {
	#write version at first byte
	push(@a,0x40<<$REGNR | $c << 24 | $WRITE | 0x1);
	$c++;
	#write register at next byte
	push(@a,0x40<<$REGNR | $c << 24 | $WRITE | ($q[$i]));
	$c++;
	my $b = sendcmd($q[$i]<<$REGNR | $READ);
	#write register content at next 2 bytes
	push(@a,0x40<<$REGNR | $c << 24 | $WRITE | (($b->{$endpoint} & 0xff00) >> 8));
	$c++;
	push(@a,0x40<<$REGNR | $c << 24 | $WRITE | ($b->{$endpoint} & 0xff));
        $c++;
	if ($c eq 16) {
	    $c=0;
	    sendcmd16(@a);
	    while (flash_is_busy()) {
		#printf(" busy - try again\n");
		usleep(300000);
	    }
	    sendcmd(0x51<<$REGNR | $WRITE | 0x4);
	    sendcmd(0x50<<$REGNR | $WRITE | $page);
	    $page++;
	    @a = ();
	}
    }
    if ($c > 0) {
	for (my $i=$c;$i<16;$i++) {
	    #padding
	    push(@a,0x40<<$REGNR | $c << 24 | $WRITE);
	    $c++;
	}
        sendcmd16(@a);
	while (flash_is_busy()) {
            #printf(" busy - try again\n");                                                                                       
	    usleep(300000);
	}
	sendcmd(0x51<<$REGNR | $WRITE | 0x4);
	sendcmd(0x50<<$REGNR | $WRITE | $page);
    }
#    foreach my $e (@a) {
#	printf(" %02x \n", $e);
#    }
}


if ($execute eq "fifo" || $execute eq "ffarr") {
  my $b = sendcmd(0x200f0000);
  foreach my $e (sort keys %$b) {
    printf("endpoint: 0x%04x  chain: %d  fifo: 0x%04x\n",$e,$chain,$b->{$e}&0xffff);
  }
}


if ($sendcmd_executed_once == 0) {
  print "no command was executed. Given command \"$execute\" seems to be unknown. use \"-h\" for help.\n";
  # no command found
  #usage();
  exit;
}

