#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use Dmon;

my %config = Dmon::StartUp();

while(1) {
  my $regs = trb_registertime_read_mem($config{MBSAddress},0xb800, 0, 2);
  my $rates = Dmon::MakeRate(0,32,1,$regs);
  
  if( defined $rates) {
    my $ctrlReg = $rates->{$config{MBSAddress}}{value}[0];
    my $mbsRate = sprintf("%d",$rates->{$config{MBSAddress}}{rate}[1]);
    my $rdoEnable = $ctrlReg & 1;
    my $errReg = $ctrlReg & 0x80;
    
 
    my $title    = "MBS Recv. Rate";
    my $longtext = sprintf "%d words/s. Last word: 0x06x", $mbsRate, $ctrlReg & 0xffffff;
    my $status = Dmon::OK;
    if ($errReg) {
      $status = Dmon::ERROR;
    } elsif (!$rdoEnable) {
      $longtext = "NO READOUT. $longtext";
      $status = Dmon::WARN;
    } elsif ($mbsRate < 1000) {
      $status = Dmon::WARN;
    }
      
    Dmon::WriteQALog($config{flog},"mbs",5,$status,$title,$mbsRate,$longtext);
  }
  
  usleep(8e5);
}

