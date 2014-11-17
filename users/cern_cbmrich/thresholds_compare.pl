#!/usr/bin/perl -w

use warnings;
use strict;
use POSIX qw(strftime);
use FileHandle;
use lib "../../tools";
use lib ".";
use HPlot;
use Data::Dumper;
use ChannelMapping;

my $plot2 = ();
$plot2->{name}    = "HeatmapRich";
$plot2->{file}    = "thresh_heatmap";
$plot2->{entries} = 33;
$plot2->{curves}  = 33;
$plot2->{type}    = HPlot::TYPE_HEATMAP;
$plot2->{output}  = HPlot::OUT_PNG;
$plot2->{zlabel}  = "Hitrate";
$plot2->{sizex}   = 700;
$plot2->{sizey}   = 650;
$plot2->{nokey}   = 1;
$plot2->{buffer}  = 0;
$plot2->{xmin}    = 0.5;
$plot2->{xmax}    = 32.5;
$plot2->{ymin}    = 0.5;
$plot2->{ymax}    = 32.5;
$plot2->{cbmin}   = "-400<*";
$plot2->{cbmax}   = "*<400";
$plot2->{showvalues} = 0;
$plot2->{xlabel} = "column";
$plot2->{ylabel} = "row";
$plot2->{addCmd} = "set lmargin at screen 0.07\nset rmargin at screen 0.85\nset bmargin at screen 0.07\nset tmargin at screen 0.95";
$plot2->{palette} = "defined (  0 0 0 1,  0.5 1 1 1,  1 1 0 0 )";

HPlot::PlotInit($plot2);

sub readSettings {
  my $fn = shift;
  open(my $fh,  $fn) || die "could not open file '$fn'";
  my @f = <$fh>;
  close $fh;

  my %thresholds = ();
  my $count=0;
  foreach my $cl (@f) {
    (my $ep, my $chain, my $channel, my $thresh, my $uid) = 
      $cl =~ /endpoint:\s+(\w+), chain:\s+(\d+), channel:\s+(\d+) threshold:\s+(\w+), uid: (\w+)/;
    next unless defined $ep;
    $thresholds{hex($ep) .":". int($channel)} = hex $thresh;
  }

  return %thresholds;
}

# load files
  my $fn1 = $ARGV[0] or die("usage: thresholds_compare.pl file1 [file2]. omit file2 to get abs value, include for file1-file2");
  my $fn2 = $ARGV[1];

  my %threshs1 = readSettings($fn1);
  print "WARNING: Expected 1024 settings in $fn1. Got " . scalar(keys %threshs1) unless scalar(keys %threshs1) == 1024; 

  my %threshs2 = ();
  if ($fn2) {
    %threshs2 = readSettings($fn2);
    print "WARNING: Expected 1024 settings in $fn2. Got " . scalar(keys %threshs2) unless scalar(keys %threshs2) == 1024; 
  }

# plot heatmap
  for my $x (1..32) {
    for my $y (1..32) {
      my $fpga    = $ChannelMapping::chanmap->{fpga}->[$x]->[$y];
      my $channel = ($ChannelMapping::chanmap->{chan}->[$x]->[$y]-1)/2;
      
      unless (defined $threshs1{$fpga.":".$channel}) {
        printf("endpoint 0x%04x, channel %d (%d:%d) not found in $fn1", $fpga, $channel, $fpga, $channel);
        next;
      }

      my $value = $threshs1{$fpga.":".$channel};
      if ($fn2) {
        if (defined $threshs2{$fpga.":".$channel}) {
          $value -= $threshs2{$fpga.":".$channel};
        } else {
          printf("endpoint 0x%04x, channel %d (%d:%d) not found in $fn2", $fpga, $channel, $fpga, $channel);
        }
      }

      HPlot::PlotFill('HeatmapRich',$value,$x,$y);
    }
  }
  HPlot::PlotDraw('HeatmapRich');      

# plot histogram
  my @values = ();

  open DATA, ">", "/tmp/thresh_diff.dat";
  for my $key (keys %threshs1) {
    print DATA $threshs1{$key} . " " . $threshs2{$key} . "\n";
    push @values, $threshs1{$key};
    push @values, $threshs2{$key};
  }
  close DATA;

  @values = sort @values;
  
  my $min = $values[int($#values * 0.02)];
  my $max = $values[int($#values * 0.92)];
  my $range = $max-$min;

  $min -= $range * 0.1;
  $max += $range * 0.1;


  open GNUPLOT, '|gnuplot';
  print GNUPLOT <<CMD
set terminal png size 700,650
set output "thresh_hist.png"

set xrange [$min:$max]

binwidth=20
bin(x,width)=width*floor(x/width)

set style line 1 lt 1 lc rgb "green"
set style line 2 lt 1 lc rgb "red"
set style fill solid noborder

plot \\
  '/tmp/thresh_diff.dat' using (bin(\$1,binwidth)):(1.0) smooth freq with boxes lc 1 title '$fn1', \\
  '/tmp/thresh_diff.dat' using (bin(\$2,binwidth)):(1.0) smooth freq with boxes lc 2 title '$fn2'
CMD
;
  close GNUPLOT;
  


