#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;

use HADES::TrbNet;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use Dmon;
use HPlot;
use Data::Dumper;
use Perl2Epics;

my %config = Dmon::StartUp();
my $t0;

for(my $i = 0; $i< 16 ; $i++) {
  Perl2Epics::Connect("PC".$i, sprintf('CBM:PWRSWITCH:GetCurrent%02X',$i));

  Perl2Epics::Connect("HV_U".$i, sprintf('OUTPUT_TERMINAL_VOLTAGE_U%d',$i));
  Perl2Epics::Connect("HV_I".$i, sprintf('MEASUREMENT_CURRENT_U%d',$i));
}

Perl2Epics::Connect("Pres","CBM:BMP180:GetPressure");
Perl2Epics::Connect("Temp","CBM:BMP180:GetTemp");

while(1) {
# update billboard
  my @billboardValues = ();
  my $reg;

  my $epicsData = Perl2Epics::GetAll();

  # temp & pressure
  push @billboardValues,
    (( 0                      )      << 30) | # version   2 bit
    (($epicsData->{"Pres"}->{"val"} & 0x1fffff) <<  9) | # pressure 21 bit
    (($epicsData->{"Temp"}->{"val"} & 0x1ff   ) <<  0);  # temp      9 bit

  # padiwa currents
  for(my $i = 0; $i < 16; $i++) {
    my $milAmp = $epicsData->{"PC".$i}->{"val"} * 1000;
    $reg = 0 unless $i & 1;
    $reg |= ($milAmp & 0xffff) << (16 * ($i&1));
    
    push(@billboardValues, $reg) if ($i & 1);
  }
  

  # threshold timestamp
  my $threshTime = do($config{UserDirectory} . '/thresh/billboard_info');
  push @billboardValues, ($threshTime & 0xffffffff);
  
  # hv values
  for(my $i=0; $i < 16; $i++) {
    push @billboardValues,
      ((($epicsData->{"HV_I".$i}->{"val"} * 1e6) & 0xffff) << 16) |
      ((($epicsData->{"HV_U".$i}->{"val"} * 1e2) & 0xffff) <<  0);
      
    #print(($epicsData->{"HV_I".$i}->{"val"} * 1e6) . "uA @ " . ($epicsData->{"HV_U".$i}->{"val"} * 1e3) . " mV \n");
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

