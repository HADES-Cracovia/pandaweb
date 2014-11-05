#!/usr/bin/perl -w

use warnings;
use lib "./code";
use lib "../tools";
use HADES::TrbNet;
use Dmon;
use HPlot;
use Data::Dumper;


my %config = Dmon::StartUp();


HPlot::PlotInit({
  name    => "PadiwaTemp",
  file    => Dmon::DMONDIR."PadiwaTemp",
  entries => scalar @{$config{PadiwaTrbAdresses}},
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

  foreach my $b (@{$config{PadiwaTrbAdresses}}) {
    $i++;
    my $r = Dmon::PadiwaSendCmd(0x10040000,$b,0);
    unless (defined $r) {
      $notonline .= sprintf(" %04x",$b);
      $notonlinecnt++;
      next;
      }
    my $temp = (($r->{$b} & 0xFFF))/16;
    unless ($temp < 10 || $temp > 90) {
      if ($max < $temp) {
        $max = $temp;
        $maxboard = $b;
        }
      elsif ($min > $temp) { 
        $min = $temp;
        $minboard = $b;
        }
      HPlot::PlotFill('PadiwaTemp',$temp,$i);      
      }  
    else {
      HPlot::PlotFill('PadiwaTemp',10,$i);      
      $notonline .= sprintf(" %04x",$b);
      $notonlinecnt++;
      }
    }
  
  my $title    = "Temperature";
  my $value    = sprintf("%.1f",$max);
  my $longtext = sprintf("Maximum: %.1f on board 0x%04x<br>Minimum: %.1f on board 0x%04x",$max,$maxboard,$min,$minboard);
  my $status   = Dmon::GetQAState('below',$max,(50,60,70));
  Dmon::WriteQALog($config{flog},"padiwatemp",30,$status,$title,$value,$longtext,"10-PadiwaTemp");

  $title    = "Online";
  $value    = sprintf("%i / %i",(scalar @{$config{PadiwaTrbAdresses}})-$notonlinecnt,scalar @{$config{PadiwaTrbAdresses}});
  $longtext = "Boards not reacting:".$notonline;
  $status   = Dmon::GetQAState('above',$notonlinecnt,(0,1,4));
  Dmon::WriteQALog($config{flog},"padiwaonline",30,$status,$title,$value,$longtext,"10-PadiwaOnline");  
  
  HPlot::PlotDraw('PadiwaTemp');

  sleep(15);
}
