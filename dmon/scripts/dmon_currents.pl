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
  name    => "PadiwaCurrents",
  file    => Dmon::DMONDIR."PadiwaCurrents",
  curves  => 16,
  entries => 300,
  type    => HPlot::TYPE_HISTORY,
  output  => HPlot::OUT_PNG,
  xlabel  => "Time [s]",
  ylabel  => "Current [A]",
  sizex   => 750,
  sizey   => 270,
  nokey   => 1,
  buffer  => 1
  });

my $str = Dmon::MakeTitle(10,6,"PadiwaCurrents",0);
   $str .= qq@<img src="%ADDPNG PadiwaCurrents.png%" type="image/png">@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("PadiwaCurrents",$str);

for(my $i = 0; $i<16; $i++) {
  my $name = sprintf('CBM:PWRSWITCH:GetCurrent%02X',$i);
  Perl2Epics::Connect("C".$i,$name);
  }



while (1) {

  # get data from epics
  my $data = Perl2Epics::GetAll();
  my $maximum = 0;
  my $total = 0;

  for(my $i = 0; $i<16; $i++) {
    my $val = $data->{"C".$i}->{"val"};
    $total += $val || 0;
    $maximum = max($maximum,$val||0);
    HPlot::PlotAdd('PadiwaCurrents',$val,$i);
    }
  HPlot::PlotDraw('PadiwaCurrents');

    my $title    = "Currents";
    my $value    = sprintf("%.2fA / %.2fA", $maximum, $total);
    my $longtext = "Maximum / Total current: ". $value;
    my $status   = Dmon::OK;
    Dmon::WriteQALog($config{flog},"currents",30,$status,$title,$value,$longtext,'2-PadiwaCurrents');


  sleep 1;
  }





