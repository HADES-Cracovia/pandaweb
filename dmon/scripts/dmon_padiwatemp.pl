#!/usr/bin/perl -w

use warnings;
use HADES::TrbNet;
use Dmon;
use HPlot;
use Data::Dumper;


my %config = Dmon::StartUp();


my $PadiwaNumber = 0;
foreach my $b (@{$config{PadiwaChainMask}}) {
  $PadiwaNumber++ if($b & 0x1);
  $PadiwaNumber++ if($b & 0x2);
  $PadiwaNumber++ if($b & 0x4);
  $PadiwaNumber++ if($b & 0x8);
  }

HPlot::PlotInit({
  name    => "PadiwaTemp",
  file    => Dmon::DMONDIR."PadiwaTemp",
  entries => $PadiwaNumber,
  type    => HPlot::TYPE_HISTORY,
  output  => HPlot::OUT_PNG,
  xlabel  => "Board",
  ylabel  => "Temperature",
  sizex   => 400,
  sizey   => 250,
  xscale  => 1,
  nokey   => 1,
  buffer  => 0
  });

my $str  = Dmon::MakeTitle(6,6,"PadiwaTemp",0);
   $str .= qq@<img src="%ADDPNG PadiwaTemp.png%" type="image/png">@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("PadiwaTemp",$str);  


while(1) {
  my $max = 1; 
  my $min = 100;  
  my ($maxboard, $minboard);
  my $i = -1;
  my $notonline = "";
  my $notonlinecnt = 0;
#   Dmon::PadiwaSendCmd(0x10800001,$config{PadiwaBroadcastAddress},0);
#   Dmon::PadiwaSendCmd(0x10800001,$config{PadiwaBroadcastAddress},1);
#   Dmon::PadiwaSendCmd(0x10800001,$config{PadiwaBroadcastAddress},2);
#   Dmon::PadiwaSendCmd(0x10800000,$config{PadiwaBroadcastAddress},0);
#   Dmon::PadiwaSendCmd(0x10800000,$config{PadiwaBroadcastAddress},1);
#   Dmon::PadiwaSendCmd(0x10800000,$config{PadiwaBroadcastAddress},2);
#   sleep(2);
  foreach(my $in = 0; $in < scalar @{$config{PadiwaTrbAddresses}}; $in++) {
    my $b = $config{PadiwaTrbAddresses}[$in];
    foreach my $chain (0..3) {
      next unless ($config{PadiwaChainMask}->[$in]&(1<<$chain));
      $i++;
      my $r = Dmon::PadiwaSendCmd(0x10040000,$b,$chain);
      unless (defined $r) {
        $notonline .= sprintf(" %04x",$b.'.'.$chain);
        $notonlinecnt++;
        next;
        }
      my $temp = (($r->{$b} & 0xFFF))/16;
      unless ($temp < 10 || $temp > 90) {
        if ($max < $temp) {
          $max = $temp;
          $maxboard = $b.'.'.$chain;
          }
        if ($min > $temp) { 
          $min = $temp;
          $minboard = $b.'.'.$chain;
          }
        HPlot::PlotFill('PadiwaTemp',$temp,$i);      
        }  
      else {
        my $t = Dmon::PadiwaSendCmd(0x10010000,$b,$chain);
        HPlot::PlotFill('PadiwaTemp',10,$i);      
        #print Dumper $t;
        if(($t & 0xFF) != 0x28) {
          $notonline .= sprintf(" %04x.%1i",$b,$chain);
          $notonlinecnt++;
          }
        }
      }  
    }
  
  my $title    = "Temperature";
  my $value    = sprintf("%.1f",$max);
  my $longtext = sprintf("Maximum: %.1f on board 0x%04x<br>Minimum: %.1f on board 0x%04x",$max,$maxboard,$min,$minboard);
  my $status   = Dmon::GetQAState('below',$max,(65,70,75));
  Dmon::WriteQALog($config{flog},"padiwatemp",30,$status,$title,$value,$longtext,"10-PadiwaTemp");

  $title    = "Online";
  $value    = sprintf("%i / %i",$PadiwaNumber-$notonlinecnt,$PadiwaNumber);
  $longtext = "Boards not reacting:".$notonline;
  $status   = Dmon::GetQAState('below',$notonlinecnt,(0,1,4));
  Dmon::WriteQALog($config{flog},"padiwaonline",30,$status,$title,$value,$longtext,"10-PadiwaOnline");  
  
  HPlot::PlotDraw('PadiwaTemp');

  sleep(15);
}
