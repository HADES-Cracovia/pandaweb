#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use lib "./code";
use lib "../tools";
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use Dmon;

my %config = Dmon::StartUp();

my $title    = "CNet Sync.";

while(1) {
  my $regs = trb_register_read_mem($config{CtsAddress},0xa900, 0, 13);
  my $longtext;
  my $status = Dmon::OK;
  my $value = "";
  my $dlmCnt = -1;
  
  if( defined $regs->{$config{CtsAddress}}) {
    my $linkActive    = $regs->{$config{CtsAddress}}[0] & 0x20;
    my $pulserFreqKHz = 125e3 / $regs->{$config{CtsAddress}}[1];
    $dlmCnt = $linkActive ? $regs->{$config{CtsAddress}}[0xa] : -1;
    
    $value = "$dlmCnt DLMs";
    $longtext = sprintf "DLMs: %s, Pulser: %d KHz", $dlmCnt, $pulserFreqKHz;
    
    if (!$linkActive) {
      $longtext = "CBMNet link inactive";
      $value = "no link";
      $status = Dmon::FATAL;
    } elsif (!$dlmCnt) {
      $status = Dmon::ERROR;
    }
      
  } else {
    $status = Dmon::FATAL;
    $value = "no endpoint";
    $longtext = "Endpoint not reached";
  }
  
  Dmon::WriteQALog($config{flog},"cbmnetsync",2,$status,$title,$value,$longtext);
  usleep(1e6);
}

