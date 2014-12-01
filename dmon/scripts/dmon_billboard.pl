#!/usr/bin/perl -w

# Comments:
#  - Some values had to be multiplied to achive a fixed-point representation.
#    To decode just divide by the factor specified for each value
#
#  - We added values (by appending) during the beam time so earlier files 
#    might miss values from the bottom of the table
#
# Word  Bits    Factor  Epics-Name                            Description
#  0    0 : 8   10      CBM:BMP180:GetTemp                    Gas Temperatur in °C measured in Box
#       29: 9   1       CBM:BMP180:GetPressure                Gas Pressure in Pa measured in Box
#       31:30                                                 Data Format version: 0x00
#                                                             
#  1    15: 0   1       CBM:PWRSWITCH:GetCurrent00            Current measured for Padiwa-Supply  1 in mA
#       31:15   1       CBM:PWRSWITCH:GetCurrent01            Current measured for Padiwa-Supply  2 in mA
#  2    15: 0   1       CBM:PWRSWITCH:GetCurrent02            Current measured for Padiwa-Supply  3 in mA
#       31:15   1       CBM:PWRSWITCH:GetCurrent03            Current measured for Padiwa-Supply  4 in mA
#  3    15: 0   1       CBM:PWRSWITCH:GetCurrent04            Current measured for Padiwa-Supply  5 in mA
#       31:15   1       CBM:PWRSWITCH:GetCurrent05            Current measured for Padiwa-Supply  6 in mA
#  4    15: 0   1       CBM:PWRSWITCH:GetCurrent06            Current measured for Padiwa-Supply  7 in mA
#       31:15   1       CBM:PWRSWITCH:GetCurrent07            Current measured for Padiwa-Supply  8 in mA
#  5    15: 0   1       CBM:PWRSWITCH:GetCurrent08            Current measured for Padiwa-Supply  9 in mA
#       31:15   1       CBM:PWRSWITCH:GetCurrent09            Current measured for Padiwa-Supply 10 in mA
#  6    15: 0   1       CBM:PWRSWITCH:GetCurrent0A            Current measured for Padiwa-Supply 11 in mA
#       31:15   1       CBM:PWRSWITCH:GetCurrent0B            Current measured for Padiwa-Supply 12 in mA
#  7    15: 0   1       CBM:PWRSWITCH:GetCurrent0C            Current measured for Padiwa-Supply 13 in mA
#       31:15   1       CBM:PWRSWITCH:GetCurrent0D            Current measured for Padiwa-Supply 14 in mA
#  8    15: 0   1       CBM:PWRSWITCH:GetCurrent0E            Current measured for Padiwa-Supply 15 in mA
#       31:15   1       CBM:PWRSWITCH:GetCurrent0F            Current measured for Padiwa-Supply 16 in mA
#                                                             
#  9    31:0    1                                             Unix-Timestamp of Threshold file used (based on the time information found in the first line of the Threshold-Log file)
#                                                             
# 10    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U0            HV Voltage of PMT  1 in V
#       31:16   1       MEASUREMENT_CURRENT_U0                HV Current of PMT  1 in uA
# 11    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U1            HV Voltage of PMT  2 in V
#       31:16   1       MEASUREMENT_CURRENT_U1                HV Current of PMT  2 in uA
# 12    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U2            HV Voltage of PMT  3 in V
#       31:16   1       MEASUREMENT_CURRENT_U2                HV Current of PMT  3 in uA
# 13    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U3            HV Voltage of PMT  4 in V
#       31:16   1       MEASUREMENT_CURRENT_U3                HV Current of PMT  4 in uA
# 14    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U4            HV Voltage of PMT  5 in V
#       31:16   1       MEASUREMENT_CURRENT_U4                HV Current of PMT  5 in uA
# 15    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U5            HV Voltage of PMT  6 in V
#       31:16   1       MEASUREMENT_CURRENT_U5                HV Current of PMT  6 in uA
# 16    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U6            HV Voltage of PMT  7 in V
#       31:16   1       MEASUREMENT_CURRENT_U6                HV Current of PMT  7 in uA
# 17    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U7            HV Voltage of PMT  8 in V
#       31:16   1       MEASUREMENT_CURRENT_U7                HV Current of PMT  8 in uA
# 18    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U8            HV Voltage of PMT  9 in V
#       31:16   1       MEASUREMENT_CURRENT_U8                HV Current of PMT  9 in uA
# 19    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U9            HV Voltage of PMT 10 in V
#       31:16   1       MEASUREMENT_CURRENT_U9                HV Current of PMT 10 in uA
# 20    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U10           HV Voltage of PMT 11 in V
#       31:16   1       MEASUREMENT_CURRENT_U10               HV Current of PMT 11 in uA
# 21    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U11           HV Voltage of PMT 12 in V
#       31:16   1       MEASUREMENT_CURRENT_U11               HV Current of PMT 12 in uA
# 22    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U12           HV Voltage of PMT 13 in V
#       31:16   1       MEASUREMENT_CURRENT_U12               HV Current of PMT 13 in uA
# 23    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U13           HV Voltage of PMT 14 in V
#       31:16   1       MEASUREMENT_CURRENT_U13               HV Current of PMT 14 in uA
# 24    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U14           HV Voltage of PMT 15 in V
#       31:16   1       MEASUREMENT_CURRENT_U14               HV Current of PMT 15 in uA
# 25    15: 0   100     OUTPUT_TERMINAL_VOLTAGE_U15           HV Voltage of PMT 16 in V
#       31:16   1       MEASUREMENT_CURRENT_U15               HV Current of PMT 16 in uA
#
# 26    15: 0   100     CBM:RICH:Mirror:Pos:ActualPosition1   Mirror Position 1 in °
#       31:16   100     CBM:RICH:Mirror:Pos:ActualPosition2   Mirror Position 2 in °
#
# 27    15: 0   32      CBM:RICH:Gas:O2                       O2 concentration of gas in ppm
#       31:16   32      CBM:RICH:Gas:H2O                      H2O concentration of gas in ppm
#
# 28    15: 0   12800   CBM:RICH:Gas:PT-1                     ?  
#       31:16   32      CBM:RICH:Gas:PTB                      ?
#
# 29    15: 0   32      CBM:RICH:Gas:PT-2                     ? 
#       31:16   32      CBM:RICH:Gas:PT-3                     ?
#
# 30    15: 0   128     CBM:RICH:Gas:TT-1                     ? 
#       31:16   128     CBM:RICH:Gas:TT-2                     ?
#
# 31    15: 0   16384   CBM:RICH:Gas:PT-4                     ? 
#       31:16   512     CBM:RICH:Gas:FM-1                     ?
#
# 32    31: 0   128e6   CBM:RICH:Gas:RefrIndex                ?
#
# 33    15: 0   1                                             Padiwa Threshold offset +32768

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
    my $milAmp = ($epicsData->{"PC".$i}->{"val"} or 0) * 1000;
    $reg = 0 unless $i & 1;
    $reg |= ($milAmp & 0xffff) << (16 * ($i&1));
    
    push(@billboardValues, $reg) if ($i & 1);
  }

  # threshold timestamp
  my $threshTime   = (do($config{UserDirectory} . '/thresh/billboard_timestamp')) or 0;
  my $threshOffset = (do($config{UserDirectory} . '/thresh/billboard_offset')) or 0;
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
  
  push @billboardValues, ($threshOffset & 0xffff);

  
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

