#!/usr/bin/perl
use warnings;
use strict;
use Data::Dumper;

my $dirich_concentrator_address = $ARGV[0];

unless ($ARGV[0]) {
  print "usage: dirich_scan_backplane.pl <DiRICH-Concentrator-TrbNet-Address>\n";
  exit;
}

my $c;

#($dirich_concentrator_address) = $dirich_concentrator_address =~ /0x([\w\d]+)/;

$c= "./switch_power_dirich.pl $dirich_concentrator_address all off"; qx($c);
qx($c);

sleep 1;

foreach my $cur_position (1..12) {
  $c = "./switch_power_dirich.pl $dirich_concentrator_address $cur_position on";
  #print $c . "\n";
  qx($c);
  sleep 4;
  #qx($c);

  $c = "trbcmd reset; sleep 1; ~/trbsoft/daqtools/merge_serial_address.pl $ENV{DAQ_TOOLS_PATH}/base/serials_dirich.db $ENV{USER_DIR}/db/addresses_dirich.db; sleep 1; trbcmd i 0xffff | grep ^0x12";
  my $r = qx($c);

  print "position: $cur_position: $r\n";
  $c = "./switch_power_dirich.pl $dirich_concentrator_address $cur_position off";
  qx($c);
}
