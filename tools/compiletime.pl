#!/usr/bin/perl


use Date::Format;

#print("\nCompile time of FPGA designs\n");

my $cmd;
$cmd = sprintf("trbcmd r %6s 0x40 | sort",@ARGV[0]);
my @o = qx($cmd);

foreach my $s (@o) {
  my ($a,$t);
  if (($a, $t)= $s =~ /0x(\w{4})\s*0x(\w{8})/) {
    my $str = sprintf("%4s\t%s\t%8s",$a, time2str('%Y-%m-%d %H:%M',hex($t)),$t);
    print $str."\n";
    }
  }
