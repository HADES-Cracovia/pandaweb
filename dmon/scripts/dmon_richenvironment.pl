#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use HADES::TrbNet;
# use List::Util qw(min max);
# use Time::HiRes qw(usleep);
use Dmon;
use HPlot;
use Perl2Epics;
# use Data::Dumper;

my %config = Dmon::StartUp();

HPlot::PlotInit({
  name    => "temperature",
  file    => Dmon::DMONDIR."RichEnvironmentTemperature",
  curves  => 1,
  entries => 3000,
  type    => HPlot::TYPE_HISTORY,
  output  => HPlot::OUT_PNG,
  xlabel  => "Time [m]",
  ylabel  => "Temperature",
  sizex   => 750,
  sizey   => 270,
  ymin    => 10,
  ymax    => "30<*",
  nokey   => 1,
  storable=> 1,
  buffer  => 1
  });
HPlot::PlotInit({
  name    => "pressure",
  file    => Dmon::DMONDIR."RichEnvironmentPressure",
  curves  => 1,
  entries => 3000,
  type    => HPlot::TYPE_HISTORY,
  output  => HPlot::OUT_PNG,
  xlabel  => "Time [m]",
  ylabel  => "Pressure",
  sizex   => 750,
  sizey   => 270,
  ymin    => 900,
  ymax    => 1000,
  nokey   => 1,
  storable=> 1,
  buffer  => 1
  });

my $str = Dmon::MakeTitle(10,12,"RichEnvironment",0);
   $str .= qq@<img src="%ADDPNG RichEnvironmentTemperature.png%" type="image/png">@."\n";
   $str .= qq@<img src="%ADDPNG RichEnvironmentPressure.png%" type="image/png">\n@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("RichEnvironment",$str);

Perl2Epics::Connect("T","CBM:BMP180:GetTemp");
Perl2Epics::Connect("P","CBM:BMP180:GetPressure");

my $iter = 0;

while (1) {

  # get data from epics
  my $data = Perl2Epics::GetAll();
  my $temperature = $data->{"T"}->{"val"} / 10.;
  my $pressure = $data->{"P"}->{"val"} / 100.;

  my $title    = "Environment";
  my $value    = sprintf("%.1f / %.1f", $pressure, $temperature);
  my $longtext = "Pressue (mbar) / Temperatur (°C): ". $value;
  my $status   = Dmon::OK;
#   print time."\t".$data->{"P"}->{"tme"}."\t".$data->{"T"}->{"tme"}."\n";
  if (time - $data->{"P"}->{"tme"} > 240 || time - $data->{"T"}->{"tme"} > 240) {
    $status = Dmon::WARN;
    $longtext .="<br>Updates missing";
    }

  Dmon::WriteQALog($config{flog},"richenvironment",15,$status,$title,$value,$longtext,'30-RichEnvironment');

  if($iter++ % 12 == 0) {
    HPlot::PlotAdd('temperature',$temperature);
    HPlot::PlotAdd('pressure',$pressure);
    HPlot::PlotDraw('temperature');
    HPlot::PlotDraw('pressure');
    }
  sleep 5;
  }





