#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use lib "./code";
use lib "../tools";
use lib "../users/cern_cbmrich";
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use List::Util qw[min max];
use Dmon;
use HPlot;
use Data::Dumper;
use ChannelMapping;

my %config = Dmon::StartUp();



my $plot2 = ();
$plot2->{name}    = "HeatmapRich";
$plot2->{file}    = Dmon::DMONDIR."heatmaprich";
$plot2->{entries} = 33;
$plot2->{curves}  = 33;
$plot2->{type}    = HPlot::TYPE_HEATMAP;
$plot2->{output}  = HPlot::OUT_PNG;
$plot2->{zlabel}  = "Hitrate";
$plot2->{sizex}   = 800;
$plot2->{sizey}   = 750;
$plot2->{nokey}   = 1;
$plot2->{buffer}  = 1;
$plot2->{xmin}    = 0.5;
$plot2->{xmax}    = 32.5;
$plot2->{ymin}    = 0.5;
$plot2->{ymax}    = 32.5;
$plot2->{showvalues} = 1;
$plot2->{xlabel} = "column";
$plot2->{ylabel} = "row";
HPlot::PlotInit($plot2);

my $str = Dmon::MakeTitle(12,12,"HeatmapRich",0);
   $str .= qq@<img src="%ADDPNG HeatmapRich.png%" type="image/png">@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("HeatmapRich",$str);


my $old;
my $oldtime = time();
my $time = time();
my $diff;


while (1) {
  my $t = trb_register_read_mem(0xfe48,0xc000,0,33);

  if (defined $old) {
    foreach my $b (keys %$o) {
      for my $v (0..32) {
        my $tdiff = time() - $oldtime;
        my $vdiff = (($o->{$b}->[$v]||0)&0xffffff) - (($old->{$b}->[$v]||0)&0xffffff);
        if ($vdiff < 0) { $vdiff += 2**24;}
        $diff->{$b}->[$v] = $vdiff/($tdiff|1);
        }
      }


    for my $x (0..31) {
      for my $y (0..31) {
        my $fpga    = $ChannelMapping::chanmap->{fpga}->[$x]->[$y];
        my $channel = $ChannelMapping::chanmap->{chan}->[$x]->[$y];
        HPlot::PlotFill('HeatmapRich',$diff->{$fpga}->[$channel],$x+1,$y+1);
        }
      }
    HPlot::PlotDraw('HeatmapRich');      
    }
  my $status = Dmon::OK;
  my $title  = "Heatmap";
  my $value = "";
  my $longtext = "See plot";
  Dmon::WriteQALog($config{flog},"heatmaprich",5,$status,$title,$value,$longtext,'2-HeatmapRich');
  $old = $o;
  $oldtime = time();
  sleep(1);
  }
