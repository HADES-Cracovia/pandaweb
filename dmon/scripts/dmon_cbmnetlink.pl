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

my $title    = "CNet Link";

while(1) {
  my $regs = trb_registertime_read_mem($config{CtsAddress},0xa900, 0, 13);
  my $longtext;
  my $status = Dmon::OK;
  my $value = "";
  my $dlmCnt = -1;
  
  if( defined $regs->{$config{CtsAddress}}) {
    my $rates = Dmon::MakeRate(0,16,1,$regs);
    if (defined $rates->{$config{CtsAddress}}{rate}) {
      my $linkActive    = $regs->{$config{CtsAddress}}{value}[0] & 0x20;
      my $resetRate     = $rates->{$config{CtsAddress}}{rate}[0xc];
      
      $value = sprintf("%d rst/s", $resetRate + 0.5);
      $longtext = sprintf "Link active: %s, Reset: %.1%/s", ($linkActive ? "y":"n"), $resetRate;
      
      if (!$linkActive || $resetRate >= 2) {
        $status = Dmon::ERROR;
      } elsif ($resetRate > 0) {
        $status = Dmon::WARN;
      }
    }
  } else {
    $status = Dmon::FATAL;
    $value = "no endpoint";
    $longtext = "Endpoint not reached";
  }
  
  Dmon::WriteQALog($config{flog},"cbmnetlink",2,$status,$title,$value,$longtext) if ($longtext);
  usleep(8e5);
}

