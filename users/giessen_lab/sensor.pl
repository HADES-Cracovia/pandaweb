#!/usr/bin/perl

use HADES::TrbNet;
use Data::Dumper;

trb_init_ports() or die trb_strerror();

while(1) {
  my $r = trb_register_read(0x0201,0xe010);

#  print Dumper $r;

 foreach my $board (keys %$r) {
   print "Temperatur: ";
   my $val =$r->{$board};
   print "$val \n";
  # printf("%I \n",$val);
 }

sleep(4);
}
