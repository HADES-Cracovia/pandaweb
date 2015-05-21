#!/usr/bin/perl -w

use warnings;
use strict;
use POSIX qw(strftime ceil floor);
use FileHandle;
use lib "./code";
use lib "../tools";
use lib "../users/gsi_dirc";
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use List::Util qw[min max];
use Dmon;
# use HPlot;
use Data::Dumper;
# use ChanDb;
use GD::Simple;
use List::Util qw[min max];

my %config = Dmon::StartUp();

# define the channel mapping for both detectors

my $chanDb;
my $detector=0;
for my $fpga (0x2020,0x2023) {
  print "fpga:$fpga detector:$detector\n";
  my $chan = 1;
  for my $i (0..3) {
    for my $j (0..7){
      $chanDb->[$detector]->[0]->[$i]->[$j] = {
        fpga => $fpga,
        chan => $chan
      };
      $chan+=2;
    }
  }
  $detector++;
}

# print Dumper $chanDb;




my $str = Dmon::MakeTitle(5,7,"HeatmapFlash",0);
   $str .= qq@<div style="padding:0"><img src="%ADDPNG HeatmapFlash.png%" type="image/png"></div></div>@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("HeatmapFlash",$str);


my $old;
my $oldtime = time();
my $time = time();
my $diff;


my $pmt_rows = 2;
my $pmt_cols = 1;
print "found $pmt_rows pmt rows and $pmt_cols pmt columns\n";

my $plot_filename = Dmon::DMONDIR."HeatmapFlash".".png";

my $padding_left  = 20;
my $padding_top   = 40;
my $pixel_size    = 20;
my $pmt_spacing   = 35;

# upper limit for high end of color scale
my $max_count_uclamp  = $config{HeatmapFlash}->{max_count_uclamp}||100000;
# lower limit for high end of color scale
my $max_count_lclamp  = $config{HeatmapFlash}->{max_count_lclamp}||10;
my $gliding_average_steps = $config{HeatmapFlash}->{normalization_inertia};
my $instantaneous_normalization = $config{HeatmapFlash}->{instant_normalization};
my $overscale_factor      = 1.1;

my $legend_length   = 250;
my $legend_segments = 128;
my $leg_seg_width   = ceil($legend_length/$legend_segments);

my $new_max = 0;
# my $new_min = 0;
my $max_count=0;
my $min_count=0;


while (1) {
  my $o = trb_register_read_mem(0xfe48,0xc000,0,65);
  
#   print Dumper $o;
  
  my $sum = 0;
  if (defined $old) {
    foreach my $b (keys %$o) {
      for my $v (0..65) {
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
          my $pmt_lookup = $chanDb->[$pmt_i]->[$pmt_j];
          
          for my $px_i (0..3) {
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


    my $count_range   = $max_count-$min_count;
    
    
    

    my $img = GD::Simple->new(380,480);
    my $offset_x;
    my $offset_y;
    
    for my $pmt_i (0..($pmt_rows-1)) {
      $offset_y = $padding_top + $pmt_i*($pmt_spacing + 4*$pixel_size);
      for my $pmt_j (0..($pmt_cols-1)) {
        $offset_x = $padding_left + $pmt_j*($pmt_spacing + 8*$pixel_size);
        
        my $pmt_lookup = $chanDb->[$pmt_i]->[$pmt_j];
        
        my $fpga_addr = $pmt_lookup->[0]->[0]->{fpga};
#         print "FPGA: $fpga_addr\n";
        $img->moveTo($offset_x,$offset_y-8);
        $img->string(sprintf("FPGA 0x%x",$fpga_addr));
        
        for my $px_i (0..3) {
#           print "\n";
          for my $px_j (0..7) {
            my $pixel_info  = $pmt_lookup->[$px_i]->[$px_j];
            my $fpga = $pixel_info->{fpga};
            my $channel = $pixel_info->{chan};
            
            my $val = $diff->{$fpga}->[$channel] || 0;
            unless(defined($diff->{$fpga}->[$channel])){
              print STDERR "cannot get data from FPGA ".sprintf("%x",$fpga)
              .", channel $channel\n";
            } 
            
            
#             print "$val ";
            
#             if ($px_i == 0 && $px_j == 0) {
#               print "\n";
#                 $val= 220;
#             }
            $new_max = max($val,$new_max);
#             $new_min = min($val,$new_min);
            $sum += $val;
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
    $offset_y = $padding_top + $pmt_rows*($pmt_spacing + 4*$pixel_size);
    
    #calculate relevant decimal power
    my $dpwr = floor(log($count_range)/log(10));
    if (($count_range/10**$dpwr)<=1.2) {
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
    $offset_y += 30;
    $img->moveTo($offset_x,$offset_y);
    $img->fgcolor('black');
    $img->string(strftime("%H:%M:%S", localtime()));
    
    open my $out, '>', $plot_filename or die;
    binmode $out;
    print $out $img->png;
  }
  my $status = Dmon::OK;
  my $title  = "Flash Heatmap";
  my $value = Dmon::SciNotation($sum);
  my $longtext = "See plot";
  Dmon::WriteQALog($config{flog},"heatmapflash",5,$status,$title,$value,$longtext,'1-HeatmapFlash');
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
