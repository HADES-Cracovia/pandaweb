#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use HPlot;
use Dmon;

HPlot::PlotInit({
  name    => "CBMNetLossRate",
  file    => Dmon::DMONDIR."CBMNetLossRate",
  entries => 600,
  type    => HPlot::TYPE_HISTORY,
  output  => HPlot::OUT_PNG,
  titles  => ["CBMNet Loss Rate"],
  xlabel  => "Time [s]",
  ylabel  => "RDO events lost / processed [%]",
  sizex   => 750,
  sizey   => 270,
  ymin    => -1,
  ymax    => 101,
  xscale  => 5,
  nokey   => 1,
  buffer  => 1
  });

my $str = Dmon::MakeTitle(10,6,"CBMNetLossRate",0);
   $str .= qq@<img src="%ADDPNG CBMNetLossRate.png%" type="image/png">@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("CBMNetLossRate",$str);

my %config = Dmon::StartUp();

my $title    = "CNet Readout";

while(1) {
  my $regs = trb_registertime_read_mem($config{CtsAddress},0xa806, 0, 4);
  my $longtext = 0;
  my $status = Dmon::OK;
  my $value = "";
  my $dlmCnt = -1;
  
  if( defined $regs->{$config{CtsAddress}}) {
    my $rates = Dmon::MakeRate(0,31,1,$regs);
    if (defined $rates->{$config{CtsAddress}}) {
      my $rateEventsSend = $rates->{$config{CtsAddress}}{rate}[0];
      my $rateEventsAbrt = $rates->{$config{CtsAddress}}{rate}[2];
      my $percentAbrt = $rateEventsAbrt ? 100.* $rateEventsAbrt / ($rateEventsSend+$rateEventsAbrt) : 0;
      my $rateDataKb = $rates->{$config{CtsAddress}}{rate}[3] * 0.002;
      
      $value = sprintf "%d kb/s", ($rateDataKb+0.5);
      $longtext = sprintf "Data rate: %d kb/s, Events send: %d, lost: %d/s (% 3.1f %%)", $rateDataKb, $rateEventsSend, $rateEventsAbrt, $percentAbrt;
      HPlot::PlotAdd('CBMNetLossRate',$percentAbrt,0);

      if ($percentAbrt > 2 ) {
        $status = Dmon::ERROR;
      } elsif ($percentAbrt > 0.5 || $rateDataKb < 1e-6) {
        $status = Dmon::WARN;
      }
    }
  } else {
    $status = Dmon::FATAL;
    $value = "no endpoint";
    $longtext = "Endpoint not reached";
  }
  
  if ($longtext) {
    # we've something to output .. so do it ;)
    Dmon::WriteQALog($config{flog},"cbmnetdata",2,$status,$title,$value,$longtext,'2-CBMNetLossRate');
    HPlot::PlotDraw('CBMNetLossRate');
  }
  usleep(8e5);
}

