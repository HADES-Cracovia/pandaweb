#!/usr/bin/perl -w

use warnings;
use strict;
use POSIX qw(strftime ceil floor);
use FileHandle;
use lib "./code";
use lib "./scripts";
use lib "../tools";
use lib "../users/gsi_dirc";
use lib "../perllibs/";
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use List::Util qw[min max];
use Dmon;
# use HPlot;
use Data::Dumper;
use ChanDb;
use GD::Simple;

my %config = Dmon::StartUp();



##################### draw channel mapping once ###################
eval {

    
  my $str = Dmon::MakeTitle(12,12,"ChannelMapDirc",0);
     $str .= qq@<div style="padding:0"><img src="%ADDPNG ChannelMapDirc.png%" type="image/png"></div></div>@;
     $str .= Dmon::MakeFooter();
  Dmon::WriteFile("ChannelMapDirc",$str);

  my $pmt_rows = @{$ChanDb::chanDb};
  my $pmt_cols = @{$ChanDb::chanDb->[0]};
  print "found $pmt_rows pmt rows and $pmt_cols pmt columns\n";
  
  my $plot_filename = Dmon::DMONDIR."ChannelMapDirc.png";
  
  my $padding_left    = 60;
  my $padding_top     = 40;
  my $pixel_size      = 15;
  my $pmt_spacing_x   = 60;
  my $pmt_spacing_y   = 35;
  
  
  #decide FPGA colors
  my $fpga_colors;
  for my $pmt_i (0..($pmt_rows-1)) {
    for my $pmt_j (0..($pmt_cols-1)) {
      my $pmt_lookup = $ChanDb::chanDb->[$pmt_i]->[$pmt_j];
      for my $px_i (0..7) {
          my $pixel_info  = $pmt_lookup->[$px_i]->[0];
          my $fpga = $pixel_info->{fpga};
          my $channel = $pixel_info->{chan};
          my $padiwa  = $pixel_info->{padiwa};
          $fpga_colors->{$fpga} = [];
      }
    }
  }
  my @keys = sort keys %$fpga_colors;
  my $count=0;
  
  for my $fpga (@keys) {
    my $hue =  ($count/(@keys-1));
    my @color = GD::Simple->HSVtoRGB((floor($hue*255) % 256),255-160*($count%2),255);
    $fpga_colors->{$fpga} = \@color;
    $count++;
  }
  #finished with FPGA colors

    my $img = GD::Simple->new(1024,600);
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
        my $last_fpga=-1;
        for my $px_i (0..7) {
          for my $px_j (0..7) {
            my $pixel_info  = $pmt_lookup->[$px_i]->[$px_j];
            my $fpga = $pixel_info->{fpga};
            my $channel = $pixel_info->{chan};
            my $padiwa  = $pixel_info->{padiwa};
            
            $img->bgcolor(@{$fpga_colors->{$fpga}});
            $img->fgcolor('black');
            my $tlx =$offset_x + $px_j*$pixel_size;
            my $tly =$offset_y + $px_i*$pixel_size;
            my $brx = $tlx + $pixel_size;
            my $bry = $tly + $pixel_size;
            $img->rectangle($tlx,$tly,$brx,$bry); # (top_left_x, top_left_y, bottom_right_x, bottom_right_y)
            
            $img->moveTo($tlx+3,$tly+$pixel_size);
            $img->string(sprintf("%02d",$channel));
            
            if($last_fpga != $fpga){
              $img->moveTo($tlx-40,$tly+$pixel_size);
              $img->string(sprintf("0x%x",$fpga));
              $img->fgcolor(@{$fpga_colors->{$fpga}});
              $img->moveTo($tlx-40,$tly+$pixel_size);
              $img->lineTo($tlx-5,$tly+$pixel_size);
            }
            
            $last_fpga   = $fpga;
          }
        }
      }
    }
    
    open my $out, '>', $plot_filename or die;
    binmode $out;
    print $out $img->png;
};
#####################  finished drawing channel mapping  ###################



my $str = Dmon::MakeTitle(9,10,"HeatmapDirc",0);
   $str .= qq@<div style="padding:0"><img src="%ADDPNG HeatmapDirc.png%" type="image/png"></div></div>@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("HeatmapDirc",$str);


my $old;
my $oldtime = time();
my $time = time();
my $diff;


my $pmt_rows = @{$ChanDb::chanDb};
my $pmt_cols = @{$ChanDb::chanDb->[0]};
print "found $pmt_rows pmt rows and $pmt_cols pmt columns\n";

my $plot_filename = Dmon::DMONDIR."HeatmapDirc".".png";

my $padding_left    = 20;
my $padding_top     = 40;
my $pixel_size      = 10;
my $pmt_spacing_x   = 40;
my $pmt_spacing_y   = 35;

# upper limit for high end of color scale
my $max_count_uclamp  = $config{HeatmapDirc}->{max_count_uclamp}||100000;
# lower limit for high end of color scale
my $max_count_lclamp  = $config{HeatmapDirc}->{max_count_lclamp}||10;
my $gliding_average_steps = $config{HeatmapDirc}->{normalization_inertia};
my $instantaneous_normalization = $config{HeatmapDirc}->{instant_normalization};
my $overscale_factor      = 1.1;

my $legend_length   = 560;
my $legend_segments = 128;
my $leg_seg_width   = ceil($legend_length/$legend_segments);

my $new_max = 0;
# my $new_min = 0;
my $max_count=0;
my $min_count=0;


while (1) {
  my $o = trb_register_read_mem($config{PadiwaBroadcastAddress},0xc000,0,49);
  
#   print Dumper $o;
  
  my $sum = 0;
  if (defined $old) {
    foreach my $b (keys %$o) {
      for my $v (0..49) {
        my $tdiff = time() - $oldtime;
        my $vdiff = (($o->{$b}->[$v]||0)&0xffffff) - (($old->{$b}->[$v]||0)&0xffffff);
        if ($vdiff < 0) { $vdiff += 2**24;}
        $diff->{$b}->[$v] = $vdiff/($tdiff|1);
      }
    }
    
    
    if ($instantaneous_normalization) {
      $max_count = 0;
      
      for my $pmt_i (0..($pmt_rows-1)) {
        for my $pmt_j (0..($pmt_cols-1)) {
          my $pmt_lookup = $ChanDb::chanDb->[$pmt_i]->[$pmt_j];
          for my $px_i (0..7) {
            for my $px_j (0..7) {
              my $pixel_info  = $pmt_lookup->[$px_i]->[$px_j];
              my $fpga = $pixel_info->{fpga};
              my $channel = $pixel_info->{chan};
              my $val = $diff->{$fpga}->[$channel] || 0;
              $max_count = max($max_count,$val);
            }  
          }
        }
      }
      
      $max_count = min($max_count,$max_count_uclamp);
      $max_count = max($max_count,$max_count_lclamp);
    } else {
      $new_max = min($new_max*$overscale_factor,$max_count_uclamp);
      # exponential gliding average
      $max_count = floor(($max_count*($gliding_average_steps-1) + $new_max)/$gliding_average_steps);
      $max_count = max($max_count,$max_count_lclamp);
      $new_max = 0;
    }

    
    
    
#     $new_min = $max_count_clamp;
#     print "max: $max_count min: $min_count\n";
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
            
            my $val = $diff->{$fpga}->[$channel];
            unless(defined($diff->{$fpga}->[$channel])){
              print STDERR "cannot get data from FPGA ".sprintf("%x",$fpga)
              .", channel $channel\n";
            } 
            $new_max = max($val,$new_max);
#             $new_min = min($val,$new_min);
            $sum += $diff->{$fpga}->[$channel];
            my $val_in_range = min(max($val,$min_count),$max_count)-$min_count;
            if(defined($diff->{$fpga}->[$channel])){
              $img->bgcolor(false_color($val_in_range/$count_range));
            } else {
              $img->bgcolor('black');
            }
            $img->fgcolor('black');
            my $tlx =$offset_x + $px_j*$pixel_size;
            my $tly =$offset_y + $px_i*$pixel_size;
            my $brx = $tlx + $pixel_size;
            my $bry = $tly + $pixel_size;
            $img->rectangle( $tlx,$tly,$brx,$bry); # (top_left_x, top_left_y, bottom_right_x, bottom_right_y)
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
    
    my $last_integer=-1;
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
      if ($cur_integer != $last_integer) {
#       unless($leg_seg % $legend_stepping) {
        $img->moveTo($tlx,$tly-8);
        $img->fgcolor('black');
        $img->string(kilomega($cur_integer*10**$dpwr));
      }
      $last_integer=$cur_integer;
    }
    
    $offset_x = $padding_left;
    $offset_y += 25;
    $img->moveTo($offset_x,$offset_y);
    $img->fgcolor('black');
    $img->string(strftime("%H:%M:%S", localtime()));
    
    open my $out, '>', $plot_filename or die;
    binmode $out;
    print $out $img->png;
  }
  my $status = Dmon::OK;
  my $title  = "Dirc Heatmap";
  my $value = Dmon::SciNotation($sum);
  my $longtext = "See plot";
  Dmon::WriteQALog($config{flog},"heatmapdirc",5,$status,$title,$value,$longtext,'1-HeatmapDirc');
  $old = $o;
  $oldtime = time();
  sleep(1);
}

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