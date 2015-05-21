#!/usr/bin/perl -w

use warnings;
use strict;
use POSIX qw(strftime ceil floor);
use FileHandle;
use lib "./code";
use lib "./scripts";
use lib "../tools";
use lib "../users/gsi_dirc";
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use List::Util qw[min max];
use Dmon;
# use HPlot;
use Data::Dumper;
use ChanDb_discdirc;
use GD::Simple;

my %config = Dmon::StartUp();

my $chanDb = $ChanDb_discdirc::chanDb;

my $str = Dmon::MakeTitle(9,14,"HeatmapDiscDirc",0);
   $str .= qq@<div style="padding:0"><img src="%ADDPNG HeatmapDiscDirc.png%" type="image/png" ></div></div>@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("HeatmapDiscDirc",$str);


my $old;
my $oldtime = time();
my $time = time();
my $diff;



my $plot_filename = Dmon::DMONDIR."HeatmapDiscDirc".".png";

my $padding_left    = 20;
my $padding_top     = 40;
# my $pixel_size      = 10;
# my $pmt_spacing_x   = 40;
# my $pmt_spacing_y   = 35;
my $strip_length    = 180;

my $px_per_mm       = 10;

# upper limit for high end of color scale
my $max_count_uclamp  = $config{HeatmapDiscDirc}->{max_count_uclamp}||100000;
# lower limit for high end of color scale
my $max_count_lclamp  = $config{HeatmapDiscDirc}->{max_count_lclamp}||10;
my $gliding_average_steps = $config{HeatmapDiscDirc}->{normalization_inertia};
my $instantaneous_normalization = $config{HeatmapDiscDirc}->{instant_normalization};
my $overscale_factor      = 1.1;

my $legend_length   = 560;
my $legend_segments = 128;
my $leg_seg_width   = ceil($legend_length/$legend_segments);

my $new_max = 0;
my $max_count=0;
my $min_count=0;

my $max_y_pos;

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
      
      for my $col (0..2) {
        for my $ypos (sort keys %{$chanDb->{$col}}) {
          my $fpga = $chanDb->{$col}->{$ypos}->{fpga};
          my $channel = $chanDb->{$col}->{$ypos}->{chan};
          my $val = $diff->{$fpga}->[$channel];
          $max_count = max($max_count,$val);
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
    
    my $count_range   = $max_count-$min_count;
    

    my $img = GD::Simple->new(640,640);
    my $offset_x;
    my $offset_y;
    
    $offset_y = $padding_top;
    
    for my $col (0..2) {
      my $strip_width;
      if ($col == 0){
        $strip_width = 0.5;
      } else {
        $strip_width = 0.3;
      }
      
      $offset_x = $padding_left + $col*$strip_length;
      for my $ypos (sort keys %{$chanDb->{$col}}) {
        my $fpga = $chanDb->{$col}->{$ypos}->{fpga};
        my $channel = $chanDb->{$col}->{$ypos}->{chan};
        
        my $val = $diff->{$fpga}->[$channel];
        unless(defined($val)){
          print STDERR "cannot get data from FPGA ".sprintf("%x",$fpga)
          .", channel $channel\n";
        } 
        $new_max = max($val,$new_max);
        $sum += $diff->{$fpga}->[$channel];
        my $val_in_range = min(max($val,$min_count),$max_count)-$min_count;
        if(defined($val)){
          $img->bgcolor(false_color($val_in_range/$count_range));
        } else {
          $img->bgcolor('black');
        }
        $img->fgcolor('black');
        my $tlx =$offset_x + $strip_width*$col;
        my $tly =$offset_y + $ypos*$px_per_mm;
        my $brx = $tlx + $strip_length;
        my $bry = $tly + $strip_width*$px_per_mm;
        $img->rectangle( $tlx,$tly,$brx,$bry); # (top_left_x, top_left_y, bottom_right_x, bottom_right_y)
        $max_y_pos = max($max_y_pos,$ypos);
      }
    
    }
    
    
    #now drawing the legend
    $offset_x = $padding_left;
    $offset_y = $padding_top + $max_y_pos*$px_per_mm +30 ;
    
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
      my $bry = $tly + 10;
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
  my $title  = "DiscDirc";
  my $value = Dmon::SciNotation($sum);
  my $longtext = "See plot";
  Dmon::WriteQALog($config{flog},"heatmapdiscdirc",5,$status,$title,$value,$longtext,'1-HeatmapDiscDirc');
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