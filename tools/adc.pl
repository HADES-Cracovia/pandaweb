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
  print 'usage: adc.pl $FPGA $cmd [$value]',"\n\n";
  print "\t time\t\t read compile time of MachXO firmware\n";
  print "\t led\t\t set/read onboard LEDs controlled by MachXO\n";
  print "\t init_lmk\t init the clock chip\n";
  exit;
}

# define "constants" to make code more readable
# chain=0 : MachXO on addon
# chain=1 : 1st chain on Addon connector SPI_CONN_L
# chain=2 : 2nd chain on Addon connector SPI_CONN_H
# chain=3 : ADC chains (CS via MachXO!)
# chain=4 : 1st LMK clock chip
# chain=5 : 2nd LMK clock chip
# see VHDL of periph FPGA for details
my %chain = (
             'machxo'  => 0,
             'addon_0' => 1,
             'addon_1' => 2,
             'adc'     => 3,
             'lmk_0'   => 4,
             'lmk_1'   => 5
            );

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

if ($ARGV[1] eq "init_lmk") {
  # start with the first lmk, the input P_CLOCK is driven by a PLL
  # the the LMKs just need to distribute it, so CLK MUX should be 0x0

  print ">>> Programming first LMK: Issue reset\n";
  # bit31 is reset
  sendcmd(0x80000000, $chain{lmk_0});
  # CE is bit27, ClkIn_select is bit29
  print "Programming R14=0xE: global clock enable, select ClkIn_0, no power down\n";
  sendcmd(0x6800000E, $chain{lmk_0});

  # bit16 is the clock enable,
  # bit8 is the unused divider setting, but 0x0 is invalid, so set it to 0x1
  print "Enable ClkOut_0=ADC9\n";
  sendcmd(0x00010100, $chain{lmk_0});
  print "Enable ClkOut_1=ADC12\n";
  sendcmd(0x00010101, $chain{lmk_0});
  # ClkOut2 is unconnected
  print "Enable ClkOut_3=2nd LMK\n";
  sendcmd(0x00010103, $chain{lmk_0});
  print "Enable ClkOut_4=ADC1\n";
  sendcmd(0x00010104, $chain{lmk_0});
  print "Enable ClkOut_5=ADC3\n";
  sendcmd(0x00010105, $chain{lmk_0});
  print "Enable ClkOut_6=ADC8\n";
  sendcmd(0x00010106, $chain{lmk_0});
  print "Enable ClkOut_7=ADC7\n";
  sendcmd(0x00010107, $chain{lmk_0});

  # similar for the second LMK
  print ">>> Programming second LMK: Issue reset\n";
  sendcmd(0x80000000, $chain{lmk_1});
  print "Programming R14=0xE: global clock enable, select ClkIn_0, no power down\n";
  sendcmd(0x6800000E, $chain{lmk_1});
  print "Enable ClkOut_0=ADC11\n";
  sendcmd(0x00010100, $chain{lmk_1});
  print "Enable ClkOut_1=ADC10\n";
  sendcmd(0x00010101, $chain{lmk_1});
  print "Enable ClkOut_2=ADC6\n";
  sendcmd(0x00010102, $chain{lmk_1});
  print "Enable ClkOut_3=ADC5\n";
  sendcmd(0x00010103, $chain{lmk_1});
  print "Enable ClkOut_4=ADC4\n";
  sendcmd(0x00010104, $chain{lmk_1});
  print "Enable ClkOut_5=ADC2\n";
  sendcmd(0x00010105, $chain{lmk_1});
  # ClkOut6/7 are unconnected

  print ">>> Both clock chips LMK01010 initialized.\n"
}


