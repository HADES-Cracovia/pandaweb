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
use Perl2Epics;

my %config = Dmon::StartUp();
my $t0;

for(my $i = 1; $i<=20; $i++) {
  my $name = sprintf('CBM:PWRSWITCH:GetCurrent%02x',$i);
  Perl2Epics::Connect("C".$i,$name);
}

while(1) {
# update billboard
  my @billboardValues = ();
  my $reg;

  my $epicsData = Perl2Epics::GetAll();

  # temp & pressure
  $billboardValues[0] = 0xdeadc0de;

  # currents
  for(my $i = 1; $i<=20; $i++) {
    my $milAmp = $epicsData->{"C".$i}->{"val"} * 1000;
    $reg = 0 unless $i & 1;
    $reg |= ($milAmp & 0xffff) << (16 * ($i&1));
    $billboardValues[$i / 2 + 1] = $reg;
  }

  trb_register_write_mem($config{BillboardAddress}, 0xb100, 0, \@billboardValues, scalar @billboardValues); # copy data
  trb_register_write($config{BillboardAddress}, 0xb000, scalar @billboardValues); # commit

# build statistics
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
  usleep(5e5);
}

