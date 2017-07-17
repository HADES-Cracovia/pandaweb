#!/usr/bin/perl -w

use warnings;
use HADES::TrbNet;
use Dmon;
use Time::HiRes qq|usleep|;
use Data::Dumper;

trb_init_ports() or die trb_strerror();

sub count {
  my $dirich   = trb_read_uid(0xfe51);
  my $combiner = trb_read_uid(0xfe52);
  printf("Combiners: %i\tDiRich: %i\n",scalar keys %$combiner, scalar keys %$dirich);
  }

count();  
  
my $act_ports = trb_register_read(0xfe52,0x84); #active ports
my $to_ports  = trb_register_read(0xfe52,0x8b); #ports with timeouts


foreach my $combs (keys %$act_ports) {
  #not active or timeout
  my $mask = (((~$act_ports->{$combs}) & 0x1ffe) or ($to_ports->{$combs} & 0x1ffe));
  #shift for LDO switch
  $mask <<= 15;
  printf("%04x\t%08x\t%08x\t%08x\n",$combs,$act_ports->{$combs},$to_ports->{$combs},$mask);
  next if $mask == 0;
  trb_register_setbit($combs,0xd580,$mask);
  usleep(10000);
  trb_register_clearbit($combs,0xd580,$mask);
  }
usleep(800000);  
count();
