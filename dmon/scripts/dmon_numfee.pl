#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use HADES::TrbNet;
use Dmon;

my %config = do $ARGV[0];
my $flog = Dmon::OpenQAFile();
trb_init_ports() or die trb_strerror();


while(1) {
  my $r = trb_register_read(0xffff,0);
  my $num = scalar keys %$r; 

  my $title    = "FPGA #";
  my $value    = $num."/".$config{NumberOfFpga};
  my $longtext = $num." out of ".$config{NumberOfFpga}." FPGAs are accessible in the whole system right now.";
  my $status   = Dmon::GetQAState('above',$num,($config{NumberOfFpga},$config{NumberOfFpga}-1,$config{NumberOfFpga}-2));
  
  
  Dmon::WriteQALog($flog,"numfee",20,$status,$title,$value,$longtext);

  sleep(10);
}
