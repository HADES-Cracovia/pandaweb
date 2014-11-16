#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use Dmon;
use HPlot;
use Data::Dumper;

my %config = Dmon::StartUp();


my $deadtimePercent;
my $cnt = 0;

HPlot::PlotInit({
  name    => "CtsDeadTime",
  file    => Dmon::DMONDIR."CtsDeadTime",
  entries => 600,
  type    => HPlot::TYPE_HISTORY,
  output  => HPlot::OUT_PNG,
  titles  => ["Dead Time"],
  xlabel  => "Time [s]",
  ylabel  => "Dead Time / Time [%]",
  sizex   => 750,
  sizey   => 270,
  ymin    => -1,
  ymax    => 101,
  xscale  => 5,
  nokey   => 1,
  buffer  => 1
  });

my $str = Dmon::MakeTitle(10,6,"CtsDeadTime",0);
   $str .= qq@<img src="%ADDPNG CtsDeadTime.png%" type="image/png">@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("CtsDeadTime",$str);

while(1) {
  my $r = trb_registertime_read($config{CtsAddress},0xa00e) ;
  my $t; $t = Dmon::MakeRate(0,32,1,$r)   if( defined $r );

  if( defined $t) { 
    $deadtimePercent = 100 * $t->{$config{CtsAddress}}{rate}[0] * 1e-8;
   
    HPlot::PlotAdd('CtsDeadTime',$deadtimePercent,0);
    
    my $title    = "Dead Time";
    my $value    = sprintf("%.2f %%", $deadtimePercent);
    my $longtext = $value." dead time";
    my $status   = Dmon::GetQAState('below',$deadtimePercent,(50,80,90));
    Dmon::WriteQALog($config{flog},"deadtime",5,$status,$title,$value,$longtext,'2-CtsDeadTime');
    HPlot::PlotDraw('CtsDeadTime');
  }
  usleep(8e5);
}

