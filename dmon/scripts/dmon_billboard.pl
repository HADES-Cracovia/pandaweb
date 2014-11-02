#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use lib "./code";
use lib "../tools";
use HADES::TrbNet;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use Dmon;
use HPlot;
use Data::Dumper;

my %config = Dmon::StartUp();
my $t0;

while(1) {
  my $title = "Billboard";
  my $longtext='';
  my $value='';
  my $status = Dmon::OK;

  my $regs = trb_registertime_read_mem($config{BillboardAddress},0xb000, 0, 5);
  
  if(defined $regs->{$config{BillboardAddress}}) {
    my $rates = Dmon::MakeRate(0,32,0,$regs);
    if (defined($rates->{$config{BillboardAddress}}{rate}) && $t0) {
      $elapsed = tv_interval ( $t0, [gettimeofday] );
      my $commitSize = $rates->{$config{BillboardAddress}}{value}[0];
      my $frameRate = $rates->{$config{BillboardAddress}}{rate}[2] / $elapsed;
      my $commitRate = $rates->{$config{BillboardAddress}}{rate}[4] / $elapsed;
 
      $value = sprintf("%.1f cmt/s", $commitRate);
      $longtext = sprintf "Commits: %d/s (size: %d b), Frames: %d/s", $commitRate, $commitSize*4, $frameRate;
      if ($commitRate == 0) {
        $status = Dmon::ERROR;
      } elsif ($frameRate < $commitRate || !$commitSize) {
        $status = Dmon::WARN;
      }
    }
  } else {
    $status = Dmon::FATAL;
    $value = "no endpoint";
    $longtext = "Endpoint not reached";
  }
  
  $t0 = [gettimeofday];
  Dmon::WriteQALog($config{flog},"billboard",6,$status,$title,$value,$longtext) if ($longtext);
  usleep(5e6);
}

