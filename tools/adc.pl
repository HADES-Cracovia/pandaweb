#!/usr/bin/perl -w
use warnings;
use strict;
use FileHandle;
use Time::HiRes qw( usleep );
use Data::Dumper;
use HADES::TrbNet;
use Date::Format;

if (!defined $ENV{'DAQOPSERVER'}) {
  die "DAQOPSERVER not set in environment";
}

if (!defined &trb_init_ports()) {
  die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
}

unless(defined $ARGV[0] && defined $ARGV[1]) {
  print 'usage: adc.pl $FPGA $cmd',"\n\n";
  print "\t time\t\t read compile time of MachXO firmware\n";
  print "\t",' led [$value]',"\t set/read onboard LEDs controlled by MachXO\n";
  print "\t",' init',"\t init LMK/ADC and set clock phase\n";
  print "\t",' lmk_init',"\t init the clock chip\n";
  print "\t",' adc_init',"\t power up and initialize ADC\n";
  print "\t",' adc_reg $addr $val',"\t write to register of all ADCs, arguments are oct()'ed\n";
  print "\t",' adc_testio $id',"\t enable testio of all ADCs, id=0 disables\n";
  print "\t",' adc_phase $phase [ADCs]',"\t set the clock-data output phase\n";
  print "\t",' adc_testall',"\t test ADC LVDS communication with pattern\n";
  exit;
}

# define "constants" to make code more readable
# chain=0 : MachXO on addon
# chain=1 : 1st frontend chain on Addon connector SPI_CONN_L
# chain=2 : 2nd frontend chain on Addon connector SPI_CONN_H
# chain=3 : ADC chains (CS via MachXO!)
# chain=4 : 1st LMK clock chip
# chain=5 : 2nd LMK clock chip
# see VHDL of periph FPGA for details
my %chain = (
             'machxo'     => 0,
             'frontend_0' => 1,
             'frontend_1' => 2,
             'adc'        => 3,
             'lmk_0'      => 4,
             'lmk_1'      => 5
            );

my @adcs = (0..11); # by default, program all ADCs
my $verbose=1;

my $board;
($board) = $ARGV[0] =~ /^0?x?(\w+)/;
$board = hex($board);


sub sendcmd {
  my $cmd = shift;
  my $chain = shift;
  die "No Chain provided" unless defined $chain;
  my $c = [$cmd,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1<<$chain,1];
  trb_register_write_mem($board,0xd400,0,$c,scalar @{$c}) or die "trb_register_write_mem: ", trb_strerror();;
  return trb_register_read($board,0xd412);
}


sub sendcmd_bitbang {
  my $cmd = shift;
  # we use the padiwa register to control
  # so set the global CSB high (and keep it high, see for loop
  trb_register_write($board,0xa080,0x51);

  my $csb_single = 0;
  for(@adcs) {
    $csb_single |= 1 << $_;
  }
  sendcmd(0x20810000+($csb_single&0xfff), $chain{machxo});

  for my $j (0..23) {
    my $b = ($cmd>>(23-$j)) & 1;
    $b = $b << 5;
    trb_register_write($board,0xa080,0x41 | $b);
    trb_register_write($board,0xa080,0x51 | $b);
  }

  sendcmd(0x20810000, $chain{machxo});
}


sub adc_init {
  print ">>> Power-up and init of ADC\n";

  #power down
  trb_register_write($board,0xa080,0x40);
  usleep(200000);

  #power on
  trb_register_write($board,0xa080,0x41);
  usleep(100000);

  #sck and csb high
  trb_register_write($board,0xa080,0x51);
  usleep(100000);


  #send commands (at least 1 needed!)
  sendcmd_adc(0x0d,0x00);
  sendcmd_adc(0xff,0x01);

  print ">>> ADC initialized\n";

  my $tries = 3;
  while(1) {
    print ">>> Optimizing ADC phases...\n";
    &set_optimal_phases;
    print ">>> Check ADCs again...\n";
    my @good = &adc_testall;
    #print Dumper(\@good);
    # check if all ADCs are good
    if(@good == grep { $_ } @good) {
      last;
    }
    elsif($tries>0) {
      print ">>> Some ADCs are not working, retrying...$tries\n";
      $tries--;
    }
    else {
      print "WARNING: Could not get all ADCs to work despite retrying...\n";
      last;
    }
  }
}

if ($ARGV[1] eq "adc_init") {
  adc_init();
}

if ($ARGV[1] eq "time") {
  my $ids;
  for (my $i = 0; $i <= 1; $i++) {
    my $b = sendcmd(0x21000000 + $i*0x10000, $chain{machxo});
    foreach my $e (sort keys %$b) {
      $ids->{$e}->{$i} = $b->{$e}&0xffff;
    }
  }
  foreach my $e (sort keys %$ids) {
    printf("0x%04x\t0x%04x%04x\t%s\n",$e,$ids->{$e}->{1},
           $ids->{$e}->{0},time2str('%Y-%m-%d %H:%M',($ids->{$e}->{1}*2**16+$ids->{$e}->{0})));
  }
}

if ($ARGV[1] eq "led") {
  my $b = sendcmd(0x20000000, $chain{machxo});
  foreach my $e (sort keys %$b) {
    printf("0x%04x\t0x%04x\n",$e,$b->{$e}&0x1f);
  }
}

if ($ARGV[1] eq "led" && defined $ARGV[2]) {
  sendcmd(0x20800000+($ARGV[2]&0x1f), $chain{machxo});
  print "Wrote LED settings.\n";
}


sub lmk_init {
  # start with the first lmk, the input P_CLOCK is driven by a PLL
  # the the LMKs just need to distribute it, so CLK MUX should be 0x0

  print ">>> Programming first LMK: Issue reset\n";
  # bit31 is reset
  sendcmd(0x80000000, $chain{lmk_0});
  # CE is bit27, ClkIn_select is bit29
  print "Programming R14=0xE: global clock enable, select ClkIn_0, no power down\n" if $verbose;
  sendcmd(0x6800000E, $chain{lmk_0});

  # bit16 is the clock enable,
  # bit8 is the unused divider setting, but 0x0 is invalid, so set it to 0x1
  print "Enable ClkOut_0=ADC9\n" if $verbose;
  sendcmd(0x00010100, $chain{lmk_0});
  print "Enable ClkOut_1=ADC12\n" if $verbose;
  sendcmd(0x00010101, $chain{lmk_0});
  # ClkOut2 is unconnected
  print "Enable ClkOut_3=2nd LMK\n" if $verbose;
  sendcmd(0x00010103, $chain{lmk_0});
  print "Enable ClkOut_4=ADC1\n" if $verbose;
  sendcmd(0x00010104, $chain{lmk_0});
  print "Enable ClkOut_5=ADC3\n" if $verbose;
  sendcmd(0x00010105, $chain{lmk_0});
  print "Enable ClkOut_6=ADC8\n" if $verbose;
  sendcmd(0x00010106, $chain{lmk_0});
  print "Enable ClkOut_7=ADC7\n" if $verbose;
  sendcmd(0x00010107, $chain{lmk_0});

  # similar for the second LMK
  print ">>> Programming second LMK: Issue reset\n";
  sendcmd(0x80000000, $chain{lmk_1});
  print "Programming R14=0xE: global clock enable, select ClkIn_0, no power down\n" if $verbose;
  sendcmd(0x6800000E, $chain{lmk_1});
  print "Enable ClkOut_0=ADC11\n" if $verbose;
  sendcmd(0x00010100, $chain{lmk_1});
  print "Enable ClkOut_1=ADC10\n" if $verbose;
  sendcmd(0x00010101, $chain{lmk_1});
  print "Enable ClkOut_2=ADC6\n" if $verbose;
  sendcmd(0x00010102, $chain{lmk_1});
  print "Enable ClkOut_3=ADC5\n" if $verbose;
  sendcmd(0x00010103, $chain{lmk_1});
  print "Enable ClkOut_4=ADC4\n" if $verbose;
  sendcmd(0x00010104, $chain{lmk_1});
  print "Enable ClkOut_5=ADC2\n" if $verbose;
  sendcmd(0x00010105, $chain{lmk_1});
  # ClkOut6/7 are unconnected

  print ">>> Both clock chips LMK01010 initialized.\n"
}

if ($ARGV[1] eq "lmk_init") {
  &lmk_init;
}

sub sendcmd_adc {
  my $adc_reg = (shift) & 0xfff; # register address
  my $adc_val = (shift) & 0xff; # register value
  printf("Set ADC Reg 0x%03x to 0x%02x\n", $adc_reg, $adc_val) if $verbose;

  # since the ADC CS lines are controlled by
  # the MachXO in reg21, we first pull the ADC CS lines low
  # by setting the lower 12 bits in reg21 to high
  #sendcmd(0x20810fff, $chain{machxo});
  
  # then we send data over the ADC SPI chain
  # the 16 higher bits are the instruction word,
  # following by one 8bit data word. the 8 lowest bits
  # should be ignored...
  # the instruction bits is simply the $adc_reg value, since
  # the bit31 should be zero for writing, and bit30/29 should be
  # 0 to request to write one byte
  sendcmd_bitbang(  ($adc_reg << 8)
          + ($adc_val << 0));#,
          #$chain{adc});

  # and set the ADC CS high again:
  # write zero to machxo reg21
  #sendcmd(0x20810000, $chain{machxo});
}

if ($ARGV[1] eq "adc_reg" && defined $ARGV[2] && defined $ARGV[3]) {
  # interpret the arguments as hex
  sendcmd_adc(oct($ARGV[2]),oct($ARGV[3]));
  # initiate transfer
  sendcmd_adc(0xFF,0x1);
  print "Wrote ADC register.\n";
}

sub adc_testio {
  my $pattern = shift;
  # interpret the arguments as hex
  sendcmd_adc(0xd, $pattern);
  # initiate transfer
  sendcmd_adc(0xFF,0x1);
  print "Set ADC testio mode for ADCs ",join(",",@adcs),"\n" if $verbose;
}

if ($ARGV[1] eq "adc_testio" && defined $ARGV[2]) {
  adc_testio(oct($ARGV[2]) & 0xf);
}

sub adc_phase {
  my $phase = shift;
  # interpret the arguments as hex
  sendcmd_adc( 0x16 , $phase );
  # initiate transfer
  sendcmd_adc(0xFF,0x1);
  print "Set ADC output phase for ADCs ",join(",",@adcs),"\n" if $verbose;
}


if ($ARGV[1] eq "adc_phase" && defined $ARGV[2]) {
  if(defined $ARGV[3]) {
    # some adc Ids given, eval this statement
    die "ADC range '$ARGV[3]' is invalid"
      unless $ARGV[3] =~ m/^[0-9.,]+$/;
    @adcs = eval $ARGV[3];
    die "Could not eval ADC range: $@"
      if $@;
    die "Empty ADC range supplied"
      if @adcs==0;
  }
  adc_phase(oct($ARGV[2]) & 0xf);
}

if ($ARGV[1] eq "init") {
  $verbose=0;
  # init stuff
  &lmk_init;
  &adc_init;
  print ">>> Your board should be working now...\n";
}

sub read_rates {
  my $addr=shift;
  my $size=shift;
  my $start=shift;
  my $bits=shift;
  my $mask = 0;
  $mask |= (1<<$_) for ($start..$start+$bits-1);

  my $us = 100000;
  # read it
  my $r1 = trb_register_read_mem($board,$addr,0,$size);
  usleep($us);
  my $r2 = trb_register_read_mem($board,$addr,0,$size);
  $r1=$r1->{$board}; # broadcasts unsupported for now...
  $r2=$r2->{$board}; # broadcasts unsupported for now...

  my @rates;
  for my $i (0..$size-1) {
    my $val1 = ($r1->[$i] & $mask) >> $start;
    my $val2 = ($r2->[$i] & $mask) >> $start;
    # detect overflow
    if($val2<$val1) {
      #print "Overflow\n";
      $val2 += 1<<$bits;
    }
    my $t1 = 0; #$r1->{time}->[$i];
    my $t2 = $us/1e6; # $r2->{time}->[$i];
    my $rate = ($val2-$val1)/($t2-$t1);
    #print $r2->{value}->[$i]-$r1->{value}->[$i],"\n";
    #print $val2-$val1," ",$rate,"\n";
    push(@rates,$rate);
  }
  return @rates;
}

if ($ARGV[1] eq "adc_testall") {
  $verbose=0;
  my @good = &adc_testall;
  for my $adc (0..11) {
    printf("ADC %02d: %s\n",$adc,
           $good[$adc] ? "Working" : "NOT WORKING!!!");
  }
}

sub adc_testall {
  my @phases =  @{(shift || [-1])}; # by default dont change phases

  # checkerboard, sends 0x2aa and 0x155 as ADC words
  adc_testio(0b0100);
  trb_register_write($board, 0xa019, 0x015502aa);
  # midscale short
  #adc_testio(0b0001);
  #trb_register_write($board, 0xa019, 0x02000200);

  my @good_ranges;
  for my $phase (@phases) {
    #print "Setting phase to ",$phase*60,"\n";
    adc_phase($phase) if $phase>=0;
    # word counts per ADC (12 items) at 0xa030 (upper 28bits)
    my @word_rates = read_rates(0xa030, 12, 4, 28);

    # invalid words per channel (4x12=48 items) at 0xa8c0
    # use only upper 31 bits to account for overflow
    my @invalid_rates = read_rates(0xa8c0, 48, 1, 31);

    for my $adc (0..11) {
      my $word_rate = $word_rates[$adc];
      my $MS = 4e7; # assume 40MS ADC...
      my $good = $word_rate > 0.98*$MS;
      for my $i (0..3) {
        my $ch = $adc*4+$i;
        my $invalid_rate = $invalid_rates[$ch];
        $good &= $invalid_rate==0 ? 1 : 0;
      }
      #printf("%02d %.0f %d\n", $adc, $word_rate, $good);
      if($phase<0) {
        $good_ranges[$adc] = $good;
      }
      else {
        $good_ranges[$adc]->[$phase] = $good;
        $good_ranges[$adc]->[$phase+@phases] = $good; # another copy to account for cyclic phase
      }
    }
  }

  # disable testio again
  adc_testio(0);
  trb_register_write($board, 0xa019, 0x0);

  return @good_ranges;
}

sub set_optimal_phases {
  $verbose=0;

  my $max_phase = 0b1011;

  my @good_ranges = adc_testall([0..$max_phase]);
  
  # find the optimal phases as largest
  # consecutive range of good state
  # then set the phases for each ADC individually
  my @old_adcs = @adcs;
  for my $adc (0..11) {
    my @good = @{$good_ranges[$adc]};
    #printf("%02d %s\n", $adc, join(' ',@good));
    # search for largest consecutive ones in @good
    my $start = -1;
    my $max_length = 0;
    my $opt_phase = -1;
    #my $end = -1;
    for(my $i=0;$i<@good;$i++) {
      if($start<0) {
        if($good[$i]) {
          #print "Found start at $i\n";
          $start=$i;
        }
      }
      else {
        if(!$good[$i] || $i==@good-1) {
          my $length = $i - $start + ($i==@good-1);
          #print "Found stop at $i with length $length\n";
          if($length>$max_length) {
            $max_length=$length;
            $opt_phase = int($start+$length/2) % ($max_phase+1);
          }
          $start = -1;
        }
      }
    }
    if($opt_phase<0) {
      print "Warning: No optimal phase found for ADC $adc, guessing 0\n";
      $opt_phase=0;
    }
    #print "Opt phase: $opt_phase Max length $max_length\n";

    # now set them for each ADC
    @adcs = ($adc); # used by adc_phase
    adc_phase($opt_phase);
    #printf("Set ADC %02d to optimal phase of %03d degrees\n", $adc, $opt_phase*60);
  }

  @adcs = @old_adcs;
}



