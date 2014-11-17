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

sub encInt {
  my $val = shift;
  my $factor = shift;
  my $bits = shift;

  $bits = 16 unless $bits;
  $factor = 1 unless $factor;  
  
  return (2 << $bits) - 1 unless defined $val;
  
  $val *= $factor;
  $val = (2 << $bits) - 1 if $val >= (2 << $bits);
  
  return $val;
}

for(my $i = 0; $i< 16 ; $i++) {
  Perl2Epics::Connect("PC".$i, sprintf('CBM:PWRSWITCH:GetCurrent%02X',$i));

  Perl2Epics::Connect("HV_U".$i, sprintf('OUTPUT_TERMINAL_VOLTAGE_U%d',$i));
  Perl2Epics::Connect("HV_I".$i, sprintf('MEASUREMENT_CURRENT_U%d',$i));
}

Perl2Epics::Connect("Pres","CBM:BMP180:GetPressure");
Perl2Epics::Connect("Temp","CBM:BMP180:GetTemp");

Perl2Epics::Connect("M1", "CBM:RICH:Mirror:Pos:ActualPosition1"); 
Perl2Epics::Connect("M2", "CBM:RICH:Mirror:Pos:ActualPosition2"); 

Perl2Epics::Connect("O2", "CBM:RICH:Gas:O2");
Perl2Epics::Connect("H2O", "CBM:RICH:Gas:H2O");
Perl2Epics::Connect("PT-1", "CBM:RICH:Gas:PT-1");
Perl2Epics::Connect("PT-2", "CBM:RICH:Gas:PT-2");
Perl2Epics::Connect("PT-3", "CBM:RICH:Gas:PT-3");
Perl2Epics::Connect("PT-4", "CBM:RICH:Gas:PT-4");
Perl2Epics::Connect("PTB", "CBM:RICH:Gas:PTB");
Perl2Epics::Connect("TT-1", "CBM:RICH:Gas:TT-1");
Perl2Epics::Connect("TT-2", "CBM:RICH:Gas:TT-2");
Perl2Epics::Connect("FM-1", "CBM:RICH:Gas:FM-1");
Perl2Epics::Connect("RefrIndex", "CBM:RICH:Gas:RefrIndex");



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
  }
  
  # mirror position
  push @billboardValues, (encInt($epicsData->{"M2"}->{"val"}   ,   100.0) << 16) | encInt($epicsData->{"M1"}->{"val"}   ,   100.0); 
  
  push @billboardValues, (encInt($epicsData->{"H2O"}->{"val"}  ,    32.0) << 16) | encInt($epicsData->{"O2"}->{"val"}   ,    32.0); 
  
  push @billboardValues, (encInt($epicsData->{"PTB"}->{"val"}  ,    32.0) << 16) | encInt($epicsData->{"PT-1"}->{"val"} , 12800.0); 
  push @billboardValues, (encInt($epicsData->{"PT-3"}->{"val"} ,    32.0) << 16) | encInt($epicsData->{"PT-2"}->{"val"} ,    32.0);
  push @billboardValues, (encInt($epicsData->{"TT-2"}->{"val"} ,   128.0) << 16) | encInt($epicsData->{"TT-1"}->{"val"} ,   128.0); 
  push @billboardValues, (encInt($epicsData->{"FM-1"}->{"val"} , 512.0) << 16) | encInt($epicsData->{"PT-4"}->{"val"} , 16384.0); 
  
  push @billboardValues,  encInt($epicsData->{"RefrIndex"}->{"val"} , 128000000.0); 
  
  #print Dumper $epicsData;
  
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

