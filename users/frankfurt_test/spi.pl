#!/usr/bin/perl -w

use warnings;
use HADES::TrbNet;
use Dmon;
use Data::Dumper;


trb_init_ports() or die trb_strerror();

my $s = Dmon::PadiwaSendCmd(0x1a804444,0x1000,0);

foreach my $k (keys $s) {
  printf("%04x %08x\n",$k,$s->{$k});
  }

sleep 1;
$s = Dmon::PadiwaSendCmd(0x20800000,0x1000,0);

foreach my $k (keys $s) {
  printf("%04x %08x\n",$k,$s->{$k});
  }

sleep 1;
$s = Dmon::PadiwaSendCmd(0x1a80000a,0x1000,0);

foreach my $k (keys $s) {
  printf("%04x %08x\n",$k,$s->{$k});
  }

sleep 1;

$s = Dmon::PadiwaSendCmd(0x21800000,0x1000,0);

foreach my $k (keys $s) {
  printf("%04x %08x\n",$k,$s->{$k});
  }

sleep 1;

$s = Dmon::PadiwaSendCmd(0x1a000000,0x1000,0);

foreach my $k (keys $s) {
  printf("%04x %08x\n",$k,$s->{$k});
  }

#f3d1
