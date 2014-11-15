#!/usr/bin/perl -w

use warnings;
use strict;
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
$plot2->{file}    = Dmon::DMONDIR."HeatmapRich";
$plot2->{entries} = 33;
$plot2->{curves}  = 33;
$plot2->{type}    = HPlot::TYPE_HEATMAP;
$plot2->{output}  = HPlot::OUT_PNG;
$plot2->{zlabel}  = "Hitrate";
$plot2->{sizex}   = 700;
$plot2->{sizey}   = 650;
$plot2->{nokey}   = 1;
$plot2->{buffer}  = 1;
$plot2->{xmin}    = 0.5;
$plot2->{xmax}    = 32.5;
$plot2->{ymin}    = 0.5;
$plot2->{ymax}    = 32.5;
$plot2->{cbmin}   = "0";
$plot2->{cbmax}   = "100<*<1000000";
$plot2->{showvalues} = 0;
$plot2->{xlabel} = "column";
$plot2->{ylabel} = "row";
$plot2->{addCmd} = "set lmargin at screen 0.07\nset rmargin at screen 0.80\nset bmargin at screen 0.07\nset tmargin at screen 0.95";
HPlot::PlotInit($plot2);

my $str = Dmon::MakeTitle(9,14,"HeatmapRich",0);
   $str .= qq@<div style="padding:0"><img src="%ADDPNG HeatmapRich.png%" type="image/png" id="heatmap-img"></div><div id="heatmap-caption" style="margin-top: -5px;"></div>@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("HeatmapRich",$str);

sub generateDef {
  my $x = 56; my $y = 51; my $w = (564-$x) / 32.0; my $h = (619-$y) / 32.0;

  $str = qq@
  var HeatmapDef = {
    'x': $x, 'y': $y, 'w': $w, 'h': $h,
    'labels': [
  @;

  for my $ix (1..32) {
    $str .= '[';
    for my $iy (1..32) {
      my $fpga    = $ChannelMapping::chanmap->{fpga}->[$ix]->[$iy];
      my $channel = ($ChannelMapping::chanmap->{chan}->[$ix]->[$iy]-1) / 2;

      $str .= sprintf("'0x%04x CH: %d'", $fpga, $channel) . ($iy == 32 ? '' : ',');
    }
    $str .= ']' . ($ix == 32 ? '' : ',') . "\n";
  }

  $str .= ']};';
  return $str;
}

open FH, ">", Dmon::DMONDIR . '/HeatmapRichDefs.js';
print FH generateDef;
close FH;

my $old;
my $oldtime = time();
my $time = time();
my $diff;


while (1) {
  my $o = trb_register_read_mem($config{PadiwaBroadcastAddress},0xc000,0,33);

  if (defined $old) {
    foreach my $b (keys %$o) {
      for my $v (0..32) {
        my $tdiff = time() - $oldtime;
        my $vdiff = (($o->{$b}->[$v]||0)&0xffffff) - (($old->{$b}->[$v]||0)&0xffffff);
        if ($vdiff < 0) { $vdiff += 2**24;}
        $diff->{$b}->[$v] = $vdiff/($tdiff|1);
        }
      }
#     print Dumper $diff;
    for my $x (1..32) {
      for my $y (1..32) {
        my $fpga    = $ChannelMapping::chanmap->{fpga}->[$x]->[$y];
        my $channel = $ChannelMapping::chanmap->{chan}->[$x]->[$y];
        HPlot::PlotFill('HeatmapRich',$diff->{$fpga}->[$channel],$x,$y);
        }
      }
    HPlot::PlotDraw('HeatmapRich');      
    }
  my $status = Dmon::OK;
  my $title  = "Heatmap";
  my $value = "";
  my $longtext = "See plot";
  Dmon::WriteQALog($config{flog},"heatmaprich",5,$status,$title,$value,$longtext,'1-HeatmapRich');
  $old = $o;
  $oldtime = time();
  sleep(1);
  }
