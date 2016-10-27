#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use lib "./code";
use lib "../tools";
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use Dmon;
use HPlot;
use Data::Dumper;
use List::Util qw(min max);
trb_init_ports() or die trb_strerror();

my %config = Dmon::StartUp();




#0 for TRB3sc, 1 for DiRich, 2 for Concentrator, 3 for PowerVoltages, 4 for PowerCurrents
my $t = [['mV (3.3)','mV (2.5)','mV (1.2)','mV (6)'],
         ['mV (3.3)','mV (2.5)','mV (1.1)',''],
         ['mV (3.3)','mV (2.5)','mV (1.2)','mA (@1.2)'],
         ['mV (3.3)','mV (2.5)','mV (1.2)','mV (1.1)'],
         ['mA (@1.1)','mA (@1.2)','mA (@2.5)','mA (@3.3)']];
my $channel = [7,7,7,6,5]; #SPI interface number

#1:4V, 2:2V, 3:1V
my $resolution = [[2,1,2,1],  [2,2,2,1],  [2,2,2,4],      [2,2,2,2],       [3,3,2,2]];
my $multiplier=  [[1,1,0.5,2],[1,1,0.5,0],[1,1,0.5,3.125],[1,1,0.5,0.5],   [2.5,1.25,1,0.5]];
my $modedesc =   [ 'Trb3sc',  'DiRich',   'Concentrator', 'Power-Voltages','Power-Currents'];



HPlot::PlotInit({
  name    => "DiRichVolt",
  file    => Dmon::DMONDIR.'DiRichVolt',
  curves  => 3,
  entries => 20,
  titles  => ['3.3V','2.56V','1.16V/1.26V'],
  type    => HPlot::TYPE_BARGRAPH,
  output  => HPlot::OUT_PNG,
  xlabel  => "Board",
  ylabel  => "Voltage (mV diff to nom)",
  sizex   => 400,
  sizey   => 200,
  ymin    => '*<-50',
  ymax    => '200<*',
  countup => 1,
  xscale  => 1,
  nokey   => 0,
  buffer  => 0,
  bargap => 0.4,
  curvewidth => 1,
  });

HPlot::PlotInit({
  name    => "PowerVolt",
  file    => Dmon::DMONDIR.'PowerVolt',
  curves  => 4,
  entries => 20,
  titles  => ['3.36V','2.56V','1.26V','1.16V'],
  type    => HPlot::TYPE_BARGRAPH,
  output  => HPlot::OUT_PNG,
  xlabel  => "Board",
  ylabel  => "Voltage (mV diff to nom)",
  sizex   => 400,
  sizey   => 200,
  ymin    => '*<-50',
  ymax    => '200<*',
  countup => 1,
  xscale  => 1,
  nokey   => 0,
  buffer  => 0,
  bargap => 0.4,
  curvewidth => 1,
  });  

HPlot::PlotInit({
  name    => "PowerCurr",
  file    => Dmon::DMONDIR.'PowerCurr',
  curves  => 4,
  entries => 20,
  titles  => ['1.1V','1.2V','2.5V','3.3V'],
  type    => HPlot::TYPE_BARGRAPH,
  output  => HPlot::OUT_PNG,
  xlabel  => "Board",
  ylabel  => "Current (mA)",
  sizex   => 400,
  sizey   => 200,
#   ymin    => '*<-50',
#   ymax    => '200<*',
  countup => 1,
  xscale  => 1,
  nokey   => 0,
  buffer  => 0,
  bargap => 0.4,
  curvewidth => 1,
  });   
  
my $str  = Dmon::MakeTitle(6,13,"DiRich Power",0);
   $str .= qq@<img src="%ADDPNG DiRichVolt.png%" type="image/png"><br>\n@;
   $str .= qq@<img src="%ADDPNG PowerVolt.png%" type="image/png"><br>\n@;
   $str .= qq@<img src="%ADDPNG PowerCurr.png%" type="image/png">\n@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("adcvolt",$str);  



sub measure {
  my ($board,$mode) = @_;
  #2 MHz SPI
  trb_register_write($board,0xd41a,25);

  my $cmd; my $s;
  my $return;
  for(my $i = 0; $i <= 4; $i++) {
    $cmd = 0xc1830000 + ($resolution->[$mode][0] << 25) + (($i % 4) << 28);
    $s = Dmon::PadiwaSendCmd($cmd,$board,$channel->[$mode]);
    if($i) {
      foreach my $t (keys %$s) {
        $return->[$i-1]{$t} = ($s->{$t}>>19&0xfff)*$multiplier->[$mode][$i-1];
        }
      }
    usleep(5000);
    }
  return $return;
  }

  
  
while(1) {

  my $ret;

  foreach my $a (@{$config{AdcTrb3sc}}) {
    $ret->[0] = measure($a,0);
    }
  foreach my $a (@{$config{AdcDiRichAddress}}) {
    $ret->[1] = measure($a,1);
    }
  foreach my $a (@{$config{AdcCombinerAddress}}) {
    $ret->[2] = measure($a,2);
    $ret->[3] = measure($a,3);
    $ret->[4] = measure($a,4);
    }


#   print Dumper $ret;
  my $longtext = '';

  foreach my $m (keys %{$ret->[1][0]}) {
    HPlot::PlotAdd('DiRichVolt',$ret->[1][0]{$m}-3300,0);
    HPlot::PlotAdd('DiRichVolt',$ret->[1][1]{$m}-2560,1);
    HPlot::PlotAdd('DiRichVolt',$ret->[1][2]{$m}-1160,2);
    }
  foreach my $m (keys %{$ret->[2][0]}) {
    HPlot::PlotAdd('DiRichVolt',$ret->[2][0]{$m}-3300,0);
    HPlot::PlotAdd('DiRichVolt',$ret->[2][1]{$m}-2560,1);
    HPlot::PlotAdd('DiRichVolt',$ret->[2][2]{$m}-1260,2);
    }  
  HPlot::PlotLimitEntries('DiRichVolt',(scalar keys %{$ret->[1][0]}) + (scalar keys %{$ret->[2][0]}));
  HPlot::PlotDraw('DiRichVolt');

  foreach my $m (keys %{$ret->[3][0]}) {
    HPlot::PlotAdd('PowerVolt',$ret->[3][0]{$m}-3360,0);
    HPlot::PlotAdd('PowerVolt',$ret->[3][1]{$m}-2560,1);
    HPlot::PlotAdd('PowerVolt',$ret->[3][2]{$m}-1260,2);
    HPlot::PlotAdd('PowerVolt',$ret->[3][3]{$m}-1160,3);
    }    
  HPlot::PlotLimitEntries('PowerVolt',(scalar keys %{$ret->[3][0]}));
  HPlot::PlotDraw('PowerVolt');

  foreach my $m (keys %{$ret->[4][0]}) {
    HPlot::PlotAdd('PowerCurr',$ret->[4][0]{$m},0);
    HPlot::PlotAdd('PowerCurr',$ret->[4][1]{$m},1);
    HPlot::PlotAdd('PowerCurr',$ret->[4][2]{$m},2);
    HPlot::PlotAdd('PowerCurr',$ret->[4][3]{$m},3);
    }    
  HPlot::PlotLimitEntries('PowerCurr',(scalar keys %{$ret->[4][0]}));
  HPlot::PlotDraw('PowerCurr');  


  my @min; my @max;
  $min[0] = min(values $ret->[1][0], values $ret->[2][0]);
  $min[1] = min(values $ret->[1][1], values $ret->[2][1]);
  $min[2] = min(values $ret->[2][2]);
  $min[3] = min(values $ret->[1][2]);
  $max[0] = max(values $ret->[1][0], values $ret->[2][0]);
  $max[1] = max(values $ret->[1][1], values $ret->[2][1]);
  $max[2] = max(values $ret->[2][2]);
  $max[3] = max(values $ret->[1][2]);    
  
  $min[10] = min(values $ret->[3][0]);
  $min[11] = min(values $ret->[3][1]);
  $min[12] = min(values $ret->[3][2]);
  $min[13] = min(values $ret->[3][3]);
  $max[10] = max(values $ret->[3][0]);
  $max[11] = max(values $ret->[3][1]);
  $max[12] = max(values $ret->[3][2]);
  $max[13] = max(values $ret->[3][3]);    

  $min[20] = min(values $ret->[4][0]);
  $min[21] = min(values $ret->[4][1]);
  $min[22] = min(values $ret->[4][2]);
  $min[23] = min(values $ret->[4][3]);
  $max[20] = max(values $ret->[4][0]);
  $max[21] = max(values $ret->[4][1]);
  $max[22] = max(values $ret->[4][2]);
  $max[23] = max(values $ret->[4][3]);    
  
  
  $longtext = "Voltage Rail: FPGA / Powerboard<br>"
  ."3.3V: $min[0]-$max[0] / $min[10]-$max[10]<br>"
  ."2.5V: $min[1]-$max[1] / $min[11]-$max[11]<br>"
  ."1.2V: $min[2]-$max[2] / $min[12]-$max[12]<br>"
  ."1.1V: $min[3]-$max[3] / $min[13]-$max[13]<br>";

  my $value = '';
  my $status = Dmon::OK;
  if($min[0]<3290  || $min[1]<2260  || $min[2]<1260  || $min[3]<1160)  {$status = Dmon::WARN}
  if($min[10]<3360 || $min[11]<2260 || $min[12]<1260 || $min[13]<1160) {$status = Dmon::WARN}
  
  Dmon::WriteQALog($config{flog},"adcvolt",30,$status,'Voltages',$value,$longtext,'2-adcvolt');

  $longtext = "Voltage Rail: Current<br>"
  ."1.1V: $min[20]-$max[20]<br>"
  ."1.2V: $min[21]-$max[21]<br>"
  ."2.5V: $min[22]-$max[22]<br>"
  ."3.3V: $min[23]-$max[23]<br>";

  $value = '';
  $status = Dmon::NOSTATE;
  $status = Dmon::OK;
  Dmon::WriteQALog($config{flog},"adccurr",30,$status,'Currents',$value,$longtext,'10-adcvolt');


# 
# my $cmd; my $s;
# 
# $cmd = 0xc1830000 + ($resolution->[$mode][0] << 25);
# $s = Dmon::PadiwaSendCmd($cmd,$board,$channel->[$mode]);
# 
# usleep(5000);
# $cmd = 0xd1830000 + ($resolution->[$mode][1] << 25);
# $s = Dmon::PadiwaSendCmd($cmd,$board,$channel->[$mode]);
# printf("0x%08x\t%i %s\n",$s->{$board},($s->{$board}>>19&0xfff)*$multiplier->[$mode][0],$t->[$mode][0]);
# 
# usleep(5000);
# $cmd = 0xe1830000 + ($resolution->[$mode][2] << 25);
# $s = Dmon::PadiwaSendCmd($cmd,$board,$channel->[$mode]);
# printf("0x%08x\t%i %s\n",$s->{$board},($s->{$board}>>19&0xfff)*$multiplier->[$mode][1],$t->[$mode][1]);
# 
# usleep(1000);
# $cmd = 0xf1830000 + ($resolution->[$mode][3] << 25);
# $s = Dmon::PadiwaSendCmd($cmd,$board,$channel->[$mode]);
# printf("0x%08x\t%i %s\n",$s->{$board},($s->{$board}>>19&0xfff)*$multiplier->[$mode][2],$t->[$mode][2]);
# 
# usleep(5000);
# $cmd = 0xf3930000;
# $s = Dmon::PadiwaSendCmd($cmd,$board,$channel->[$mode]);
# printf("0x%08x\t%i %s\n",$s->{$board},($s->{$board}>>19&0xfff)*$multiplier->[$mode][3],$t->[$mode][3]);
# 
# usleep(5000);
# $s = Dmon::PadiwaSendCmd(0,$board,$channel->[$mode]);
# printf("0x%08x\t%.2f °C\n",$s->{$board},(($s->{$board}>>19)&0xfff)/16.);
# 
# #back to normal SPI speed
# system("trbcmd w $board 0xd41a 7");
# print "\n";

  
  sleep 2;
}
  