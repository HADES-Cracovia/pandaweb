#!/usr/bin/perl
use warnings;
use strict;
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use Data::Dumper;

my $dirich = 0x1208;
my $dirich_power_module_offset = 0xd580;

my @res; my $res; my $rh_res;

my @dirich_powerbit_mapping = (1, 23, 17, 24, 18, 26, 20, 25, 19, 28, 22, 27,21);

my $dirich_concentrator_address = $ARGV[0];
my $position = $ARGV[1];
my $state = $ARGV[2];
my $positions_pattern = 1;


if (!$position || !$state || ! ($state=~/(on|off|toggle)/)  )  {
  usage();
  exit;
}

#($dirich_concentrator_address) = $dirich_concentrator_address =~ /0x([\w\d]+)/;
$dirich_concentrator_address = hex($dirich_concentrator_address);
#print $dirich_concentrator_address;


if ($position eq "all") {
  $position = 0;
  $positions_pattern = 0xffffffff;
}

my $new_state=($state eq "on") ? 0 : 1;

trb_init_ports() or die trb_strerror();

$res = trb_register_write($dirich, 0xdf80 , 0xffffffff);
if(!defined $res) {
    $res = trb_strerror();
    print "error output: $res\n";
}

$rh_res = trb_register_read($dirich_concentrator_address, $dirich_power_module_offset);
my $bitmap = $rh_res->{$dirich_concentrator_address};
if (! defined $bitmap) {
  printf "could not read bitmap from 0x%x TRBNet down?\n", $dirich_concentrator_address;
  exit;
}


#printf "old bitmap: 0x%x\n", $bitmap;

my $mask = $positions_pattern << ($dirich_powerbit_mapping[$position]-1);

if ($state eq "on") {
  $bitmap &= ~$mask;
}
elsif ($state eq "off") {
  $bitmap |= $mask;
}
elsif ($state eq "toggle") {
  my $old_bitmap = $bitmap;
  $bitmap ^= $mask;
  print "turned module $position ";
  my $diff = $old_bitmap ^ $bitmap;

  if ($bitmap & $mask) {
    print "off\n";
  }
  else {
    print "on\n";
  }
}

#printf "new bitmap: 0x%x\n", $bitmap;
trb_register_write($dirich_concentrator_address, $dirich_power_module_offset , $bitmap);

usleep (1E5);
exit;


sub usage {
  print "switch_power_dirich.pl <dirich_conc_address> <position in backplane> <on|off|toggle>\n";
}
