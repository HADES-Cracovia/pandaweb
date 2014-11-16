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


my $summing = 0; my $timesum = 0;
my $cnt = 0;

HPlot::PlotInit({
  name    => "TriggerRate",
  file    => Dmon::DMONDIR."TriggerRate",
  entries => 600,
  type    => HPlot::TYPE_HISTORY,
  output  => HPlot::OUT_PNG,
  titles  => ["Trigger Rate"],
  xlabel  => "Time [s]",
  ylabel  => "Rate [Hz]",
  sizex   => 750,
  sizey   => 270,
  xscale  => 5,
  nokey   => 1,
  buffer  => 1
  });

my $str = Dmon::MakeTitle(10,6,"TriggerRate",0);
   $str .= qq@<img src="%ADDPNG TriggerRate.png%" type="image/png">@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("TriggerRate",$str);

while(1) {
  my $r = trb_registertime_read($config{CtsAddress},0xa002) ;
  my $t;
  $t = Dmon::MakeRate(0,32,1,$r)   if( defined $r );

  if( defined $t) {
    $summing += $t->{$config{CtsAddress}}{rate}[0];
    $timesum ++;
    
    HPlot::PlotAdd('TriggerRate',$t->{$config{CtsAddress}}{rate}[0],0);
    
    unless($cnt++ % 10) {
      my $title    = "Rate";
      my $value    = int($summing/$timesum);
      my $longtext = $value." triggers pre second";
      my $status   = Dmon::GetQAState('above',$value,(15,2,1));
      Dmon::WriteQALog($config{flog},"trgrate",5,$status,$title,$value,$longtext,'2-TriggerRate');

      HPlot::PlotDraw('TriggerRate');
      $summing = 0;
      $timesum = 0;
      }
    }
  usleep(200000);
  }

