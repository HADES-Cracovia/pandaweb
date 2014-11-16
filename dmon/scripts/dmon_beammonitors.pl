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

HPlot::PlotInit({
  name    => "Beam",
  file    => Dmon::DMONDIR."BeamMonitors",
  entries => scalar @{$config{BeamDetectorsName}},
  type    => HPlot::TYPE_BARGRAPH,
  output  => HPlot::OUT_PNG,
  bartitle  => $config{BeamDetectorsName},
  xlabel  => "",
  ylabel  => "Counts/s",
  sizex   => 430,
  sizey   => 360,
  curvewidth => 1.5,
  ymin    => 0,
  ymax    => "1000<*",
#   xscale  => 5,
  nokey   => 1,
  buffer  => 1
  });

my $str = Dmon::MakeTitle(6,8,"BeamMonitors",0);
   $str .= qq@<img src="%ADDPNG BeamMonitors.png%" type="image/png">@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("BeamMonitors",$str);

my @old;

while(1) {
  my @regs;
  for (my $c = 0; $c < scalar @{$config{BeamDetectorsTrb}}; $c++) {
    my $t = trb_registertime_read($config{BeamDetectorsTrb}->[$c],$config{BeamDetectorsChan}->[$c]);
    $regs[$c] = $t->{$config{BeamDetectorsTrb}->[$c]};    
    }

  for (my $c = 0; $c < scalar @{$config{BeamDetectorsTrb}}; $c++) {
    my $value = $regs[$c]->{value}[0];
        
    $value -= $old[$c]->{value}[0] || 0;

    HPlot::PlotFill('Beam',$value,$c,0);
    }


  HPlot::PlotDraw('Beam');
  Dmon::WriteQALog($config{flog},"beammonitors",60,Dmon::OK,"Beam Monitors","","Just plotting","1-BeamMonitors");

#   my $curr = $sig->{$config{BeamTRB}} & 0xffffff;
# 
#   if($curr - $old > $config{SpillThreshold}) {
#     $value += $curr - $old||0;
#     }
#   else {
#     if ($value > 0) {
#       my $longtext = "Number of signals in last spill: ".$value;
#       my $status = Dmon::OK;
#       Dmon::WriteQALog($config{flog},"beamintensity",60,$status,$title,$value,$longtext);
#       $value = 0;
#       }
#     }      


  @old = @regs;
  sleep 1;
  }
