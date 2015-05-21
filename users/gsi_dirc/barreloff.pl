#!/usr/bin/perl


foreach my $i (0x2000..0x2013) {
  system("trbcmd w $i 0xc802 0");
  system("trbcmd w $i 0xc803 0");
  }
