#!/usr/bin/perl -w

use lib "../perllibs/";

use warnings;
use strict;
use POSIX qw(strftime floor ceil);
use FileHandle;
use HPlot;
use Data::Dumper;
# use ChannelMapping;
use lib "../dmon/scripts/";
use ChanDb;
use List::Util qw[min max];
use GD::Simple;

my $fn1 = $ARGV[0];

die("
usage: thresholds_compare.pl file1 [file2|'-'] [range_L] [range_U]
omit file2 (by writing a '-') to get abs value, include for file1-file2
unless range_L and range_U values are set, the color scale
will be adjusted automatically
") if (not(defined($fn1)) or ($fn1 eq "--help"));

my $fn2;
$fn2 = $ARGV[1] unless ($ARGV[1] eq "-");
my $range_l = $ARGV[2];
my $range_u = $ARGV[3];



# my $plot2 = ();
# $plot2->{name}    = "HeatmapRich";
# $plot2->{file}    = "thresh_heatmap";
# $plot2->{entries} = $ChannelMapping::chanmap->{xsize}+1;
# $plot2->{curves}  = $ChannelMapping::chanmap->{ysize}+1;
# $plot2->{type}    = HPlot::TYPE_HEATMAP;
# $plot2->{output}  = HPlot::OUT_PNG;
# $plot2->{zlabel}  = "Hitrate";
# $plot2->{sizex}   = 700;
# $plot2->{sizey}   = 650;
# $plot2->{nokey}   = 1;
# $plot2->{buffer}  = 0;
# $plot2->{xmin}    = 0.5;
# $plot2->{xmax}    = $ChannelMapping::chanmap->{xsize}+0.5;
# $plot2->{ymin}    = 0.5;
# $plot2->{ymax}    = $ChannelMapping::chanmap->{ysize}+0.5;
# $plot2->{cbmin}   = "-400<*" if $fn2;
# $plot2->{cbmax}   = "*<" . ($fn2 ? '400' : '45000'); 
# $plot2->{showvalues} = 0;
# $plot2->{xlabel} = "column";
# $plot2->{ylabel} = "row";
# $plot2->{addCmd} = "set lmargin at screen 0.07\nset rmargin at screen 0.85\nset bmargin at screen 0.07\nset tmargin at screen 0.95";# . ($fn2 ? "": "\n set logscale cb");
# $plot2->{palette} = "defined (  0 0 0 1,  0.5 1 1 1,  1 1 0 0 )" if $fn2;
# 
# HPlot::PlotInit($plot2);

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
    if( length($thresh) >=8) {
	#print $thresh;
	$thresh = 0xffffff;
    }
    $thresholds{hex($ep) .":". (int($channel)+ 16* int($chain)+1 )} = hex $thresh;
  }

  return %thresholds;
}

# load files

#   my $totalsize = ($ChannelMapping::chanmap->{xsize}*$ChannelMapping::chanmap->{ysize});
  my %threshs1 = readSettings($fn1);
#   print "WARNING: Expected ".$totalsize." settings in $fn1. Got " . scalar(keys %threshs1) unless scalar(keys %threshs1) == $totalsize; 

  my %threshs2 = ();
  if ($fn2) {
    %threshs2 = readSettings($fn2);
#     print "WARNING: Expected ".$totalsize." settings in $fn2. Got " . scalar(keys %threshs2) unless scalar(keys %threshs2) == $totalsize; 
  } else {
    for my $key (keys %threshs1) {
      $threshs2{$key} = 0;
    }
#     $fn2 = 'n/a';
  }

  
#   # plot heatmap w/ HPLOT
# # plot heatmap
#   for my $x (1..$ChannelMapping::chanmap->{xsize}) {
#     for my $y (1..$ChannelMapping::chanmap->{ysize}) {
#       my $fpga    = $ChannelMapping::chanmap->{fpga}->[$x]->[$y];
#       my $channel = ($ChannelMapping::chanmap->{chan}->[$x]->[$y]-1)/2;
#       
#       unless (defined $threshs1{$fpga.":".$channel}) {
#         printf("endpoint 0x%04x, channel %d (%d:%d) not found in $fn1", $fpga, $channel, $fpga, $channel);
#         next;
#       }
# 
#       my $value = $threshs1{$fpga.":".$channel};
#       if ($fn2) {
#         if (defined $threshs2{$fpga.":".$channel}) {
#           $value -= $threshs2{$fpga.":".$channel};
#         } else {
#           printf("endpoint 0x%04x, channel %d (%d:%d) not found in $fn2", $fpga, $channel, $fpga, $channel);
#         }
#       }
# 
#       HPlot::PlotFill('HeatmapRich',$value,$x,$y);
#     }
#   }
#   HPlot::PlotDraw('HeatmapRich');     
#   
#     # end of plot heatmap w/ HPLOT
    
# plot heatmap with GD

my $pmt_rows = @{$ChanDb::chanDb};
my $pmt_cols = @{$ChanDb::chanDb->[0]};
print "found $pmt_rows pmt rows and $pmt_cols pmt columns\n";

my $plot_filename = "./thresh_heatmap.png";

my $padding_left    = 20;
my $padding_top     = 40;
my $pixel_size      = 10;
my $pmt_spacing_x   = 40;
my $pmt_spacing_y   = 35;

my $legend_length   = 500;
my $legend_segments = 256;
my $leg_seg_width   = ceil($legend_length/$legend_segments);

my $max_count=0;
my $min_count=0;

my $symmetric_scale=0;


# find max counts
    for my $pmt_i (0..($pmt_rows-1)) {
      for my $pmt_j (0..($pmt_cols-1)) {
        my $pmt_lookup = $ChanDb::chanDb->[$pmt_i]->[$pmt_j];
        for my $px_i (0..7) {
          for my $px_j (0..7) {
            my $pixel_info  = $pmt_lookup->[$px_i]->[$px_j];
            my $fpga = $pixel_info->{fpga};
            my $channel = $pixel_info->{chan};
            my $val = $threshs1{$fpga.":".$channel}||0;
            if ($fn2) {
              if (defined $threshs2{$fpga.":".$channel}) {
                $val -= $threshs2{$fpga.":".$channel};
              } else {
                printf("endpoint 0x%04x, channel %d (%d:%d) not found in $fn2\n", $fpga, $channel, $fpga, $channel);
              }
            }
            $max_count = max($max_count,$val);
            $min_count = min($min_count,$val);
          }  
        }
      }
    }
    
    if ($min_count < 0){
      $symmetric_scale = 1;
    }
    if ($symmetric_scale) {
      my $max_amplitude = max(abs($max_count),abs($min_count));
      $min_count = -$max_amplitude;
      $max_count =  $max_amplitude;
    }
    
    $min_count = $range_l if (defined($range_l));
    $max_count = $range_u if (defined($range_u));
  
    
    my $count_range   = $max_count-$min_count;

    my $img = GD::Simple->new(640,480);
    my $offset_x;
    my $offset_y;
    
    for my $pmt_i (0..($pmt_rows-1)) {
      $offset_y = $padding_top + $pmt_i*($pmt_spacing_y + 8*$pixel_size);
      for my $pmt_j (0..($pmt_cols-1)) {
        $offset_x = $padding_left + $pmt_j*($pmt_spacing_x + 8*$pixel_size);
        
        my $pmt_lookup = $ChanDb::chanDb->[$pmt_i]->[$pmt_j];
        
        my $mcp_id = $pmt_lookup->[0]->[0]->{mcp};
        $img->moveTo($offset_x,$offset_y-10);
        $img->string($mcp_id);
        
        for my $px_i (0..7) {
#           print "\n";
          for my $px_j (0..7) {
            my $pixel_info  = $pmt_lookup->[$px_i]->[$px_j];
            my $fpga = $pixel_info->{fpga};
            my $channel = $pixel_info->{chan};
            
            
            my $val = $threshs1{$fpga.":".$channel};
            if ($fn2) {
              if (defined $threshs2{$fpga.":".$channel}) {
                $val -= $threshs2{$fpga.":".$channel};
              } else {
                printf("endpoint 0x%04x, channel %d (%d:%d) not found in $fn2\n", $fpga, $channel, $fpga, $channel);
              }
            }
            my $val_in_range = min(max($val,$min_count),$max_count)-$min_count;
            if(defined($val)){
              $img->bgcolor(false_color($val_in_range/$count_range));
            } else {
              $img->bgcolor('black');
            }
            $img->fgcolor('black');
            my $tlx =$offset_x + $px_j*$pixel_size;
            my $tly =$offset_y + $px_i*$pixel_size;
            my $brx = $tlx + $pixel_size;
            my $bry = $tly + $pixel_size;
            $img->rectangle($tlx,$tly,$brx,$bry); # (top_left_x, top_left_y, bottom_right_x, bottom_right_y)
          }
        }
      }
    }
    
#     print "new max: $new_max, :new_min: $new_min\n";
    
    #now drawing the legend
    $offset_x = $padding_left;
    $offset_y = $padding_top + $pmt_rows*($pmt_spacing_y + 8*$pixel_size);
    
    #calculate relevant decimal power
    my $dpwr = floor(log($count_range)/log(10));
    if (($count_range/10**$dpwr)<=2) {
      $dpwr--;
    }
    
#     print "dpwr: $dpwr\n";
    
    my $last_integer=undef;
    for my $leg_seg (0..($legend_segments-1)){
      my $val = $leg_seg/$legend_segments*$count_range+$min_count;
      my @color = false_color($leg_seg/$legend_segments);
      $img->bgcolor(@color);
      $img->fgcolor(@color);
      my $tlx =$offset_x + $leg_seg*$leg_seg_width;
      my $tly =$offset_y;
      my $brx = $tlx + $leg_seg_width;
      my $bry = $tly + $pixel_size;
      $img->rectangle( $tlx,$tly,$brx,$bry); # (top_left_x, top_left_y, bottom_right_x, bottom_right_y)
      
      #distribute nice numbers along the rainbow
      my $cur_integer = floor($val/(10**$dpwr));
      if (defined($last_integer) and ($cur_integer != $last_integer)) {
#       unless($leg_seg % $legend_stepping) {
        $img->moveTo($tlx,$tly-8);
        $img->fgcolor('black');
        $img->string(kilomega($cur_integer*10**$dpwr));
        $img->moveTo($tlx,$tly-4);
        $img->lineTo($tlx,$tly-8);
      }
      $last_integer=$cur_integer;
    }
    
    
    # print file name    
    $offset_x = $padding_left;
    $offset_y += 25;
    $img->moveTo($offset_x,$offset_y);
    $img->fgcolor('black');
    $img->string(strftime("%H:%M:%S", localtime()));
    $offset_y += 20;
    $offset_x += 10;
    $img->moveTo($offset_x,$offset_y);
    $img->string($fn1);
    if(defined($fn2)){
      $offset_y += 12;
      $offset_x = $padding_left;
      $img->moveTo($offset_x,$offset_y);
      $img->string("-");
      $offset_x += 10;
      $img->moveTo($offset_x,$offset_y);
      $img->string($fn2);
    }
    
    
    open my $out, '>', $plot_filename or die;
    binmode $out;
    print $out $img->png;
# end of plot heatmap with GD


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

binwidth=50
bin(x,width)=width*floor(x/width)

set style line 1 lt 1 lc rgb "green"
set style line 2 lt 1 lc rgb "red"
set style fill solid noborder

plot \\
  '/tmp/thresh_diff.dat' using (bin(\$1,binwidth)):(1.0) smooth freq with boxes lc 1 title '$fn1', \\
CMD
;
if (defined($fn2)){
print GNUPLOT <<CMD
  '/tmp/thresh_diff.dat' using (bin(\$2,binwidth)):(1.0) smooth freq with boxes lc 2 title '$fn2'
CMD
;
}
  close GNUPLOT;
  



sub false_color {
  my $val = $_[0]; # has to be normalized
  my $hue = 170*(1-$val);
  return GD::Simple->HSVtoRGB($hue,255,255);
}


sub kilomega {
  my $val = $_[0];
  my $num;
  if($val/1e9 >= 1){
    my $a = sprintf("%1.1fG",$val/1e9);
    $a =~ s/\.0//;
    return $a;
  } elsif ($val/1e6 >= 1){
    my $a = sprintf("%1.1fM",$val/1e6);
    $a =~ s/\.0//;
    return $a;
  } elsif ($val/1e3 >= 1){
    my $a = sprintf("%1.1fk",$val/1e3);
    $a =~ s/\.0//;
    return $a;
  } else {
    return sprintf("%d",$val);
  }
}
