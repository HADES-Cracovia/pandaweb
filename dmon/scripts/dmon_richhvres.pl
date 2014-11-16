#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use HADES::TrbNet;
use List::Util qw(min max);
use Time::HiRes qw(usleep);
use Dmon;
use HPlot;
use Perl2Epics;
use Data::Dumper;

my %config = Dmon::StartUp();

HPlot::PlotInit({
  name    => "RichHVRes",
  file    => Dmon::DMONDIR."RichHVRes",
  curves  => 16,
  entries => 300,
  type    => HPlot::TYPE_HISTORY,
  output  => HPlot::OUT_PNG,
  xlabel  => "Time [s]",
  ylabel  => "Res [MOhm]",
  sizex   => 750,
  sizey   => 270,
  nokey   => 1,
  storable=> 1,
  buffer  => 1
  });

my $str = Dmon::MakeTitle(10,6,"RichHVRes",0);
   $str .= qq@<img src="%ADDPNG RichHVRes.png%" type="image/png">@;
   $str .= Dmon::MakeFooter();

Dmon::WriteFile("RichHVRes",$str);

for(my $i = 0; $i<16; $i++) {
  Perl2Epics::Connect("HV_U".$i, sprintf('OUTPUT_TERMINAL_VOLTAGE_U%d',$i));
  Perl2Epics::Connect("HV_I".$i, sprintf('MEASUREMENT_CURRENT_U%d',$i));
}



while (1) {

  # get data from epics
  my $data = Perl2Epics::GetAll();
  
  my $minimum = 1e100;
  my $maximum = 0;
  my $total = 0;

  for(my $i = 0; $i<16; $i++) {
    my $cur = ($data->{"HV_I".$i}->{"val"} || 0);
    my $vol = ($data->{"HV_U".$i}->{"val"} || 0);
    
    next unless $cur;
    
    my $res = $vol / $cur / 1e6;

    next unless $res > 1;
    
    $minimum = min($minimum,$res);
    $maximum = max($maximum,$res);
    
    HPlot::PlotAdd('RichHVRes',$res,$i);
  }
    
  HPlot::PlotDraw('RichHVRes');

    my $title    = "HV Res";
    my $value    = sprintf("%.2fM / %.2fM", $minimum, $maximum);
    my $longtext = "Min / Max Res (Ohm): ". $value;
    my $status   = Dmon::OK;
    Dmon::WriteQALog($config{flog},"richhvres",30,$status,$title,$value,$longtext,'2-RichHVRes');


  sleep 1;
  }





