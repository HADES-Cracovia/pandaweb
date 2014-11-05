#!/usr/bin/perl -w

use warnings;
use lib "./code";
use lib "../tools";
use HADES::TrbNet;
use Dmon;
use HPlot;
use Data::Dumper;
use Time::HiRes qq|usleep|;

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

my $str = Dmon::MakeTitle(6,7,"PadiwaTemp",0);
   $str .= qq@<img src="%ADDPNG PadiwaTemp.png%" type="image/png">@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("PadiwaTemp",$str);  
  
  
sub sendcmd {
  my ($cmd,$board,$chain) = @_;
  my $c = [$cmd,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1<<$chain,0x10001];
  my $errcnt = 0;
  while(1){
    trb_register_write_mem($board,0xd400,0,$c,scalar @{$c});

    if (trb_strerror() =~ "no endpoint has been reached") {return -1;}
    if (trb_strerror() ne "No Error") {
      usleep 1E5;
      if($errcnt >= 12) {
        return "SPI still blocked\n";
        }
      elsif($errcnt++ >= 10) {
        trb_register_read($board,0xd412);
        }
      }
    else {
      last;
      }
    } 
  return trb_register_read($board,0xd412);
  }
   

while(1) {
  my $max = 1; 
  my $min = 100;  
  my ($maxboard, $minboard);
  my $i = -1;

  foreach my $b (@{$config{PadiwaTrbAdresses}}) {
    $i++;
    my $r = sendcmd(0x10040000,$b,0);
    next unless defined $r;
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
      }
    }
  
  my $title    = "Temperature";
  my $value    = sprintf("%.1f",$max);
  my $longtext = sprintf("Maximum: %.1f on board 0x%04x<br>Minimum: %.1f on board 0x%04x",$max,$maxboard,$min,$minboard);
  my $status   = Dmon::GetQAState('below',$max,(50,60,70));
  
  HPlot::PlotDraw('PadiwaTemp');
  Dmon::WriteQALog($config{flog},"padiwatemp",30,$status,$title,$value,$longtext,"10-PadiwaTemp");

  sleep(15);
}
