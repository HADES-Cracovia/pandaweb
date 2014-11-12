package HPlot;
use POSIX qw/floor ceil strftime/;
use Data::Dumper;
use warnings;
use strict;
use FileHandle;
use Storable qw(lock_store lock_retrieve);

my $p;
my $storefile;

use constant {TYPE_HISTORY => 1, TYPE_BARGRAPH => 2, TYPE_HEATMAP => 3};

use constant {OUT_PNG    => 1,
              OUT_SVG    => 2,  #n/a
              OUT_SCREEN => 3}; #n/a

my @color= ('#2222dd','#dd2222','#22dd22','#dd8822','#dd22dd','#22dddd','#dddd22','#8888dd','#8822bb','#444444',
 '#2222dd','#dd2222','#22dd22','#dd8822','#dd22dd','#22dddd','#dddd22','#8888dd','#8822bb','#444444');

sub plot_write {
  my ($file,$str,$no) = @_;
  return unless $str;
  if($no || 0) {
    print $file $str;
#     print $str;
    }
  else {
    print $file $str."\n";
#     print $str."\n";
    }
  }


sub makeTimeString{
  return strftime("set label 100 \"%H:%M:%S\" at screen 0.02,0.02 left tc rgb \"#000044\" font \"monospace,8\"\n", localtime())
  }


sub PlotInit {
  my ($c) = @_;

  my $name      = $c->{name};

  my $fn = "gnuplot";
  #my $fh = new FileHandle ("|$fn") or  die "error: no gnuplot";
  open my $fh, "|$fn" or  die "error: no gnuplot";
  $fh->autoflush(1);


  $p->{$name} = $c;
  $p->{$name}->{fh} = $fh;
  $p->{$name}->{run} = 0;
  $p->{$name}->{buffer} = $p->{$name}->{buffer} || 0;
  $p->{$name}->{sizex} = $p->{$name}->{sizex} || 600 ;
  $p->{$name}->{sizey} = $p->{$name}->{sizey} || 400 ;
  $p->{$name}->{file} = $p->{$name}->{file} || "dummy" ;
  $p->{$name}->{curves} = $p->{$name}->{curves} || 1 ;
  $p->{$name}->{xscale} = $p->{$name}->{xscale} || 1;
  $p->{$name}->{type}   or die "No plot type specified";
  $p->{$name}->{output} or die "No destination specified";
  $p->{$name}->{colors} = $p->{$name}->{colors} || \@color;
  $p->{$name}->{showvalues} = $p->{$name}->{showvalues} || 0;
  $p->{$name}->{storable} = $p->{$name}->{storable} || 0;

  my $filename = $p->{$name}->{file};
  $filename =~ s%/%%;
  $storefile->{$name} = "/dev/shm/".$name.'-'.$p->{$name}->{curves}.'-'.$p->{$name}->{entries}.'-'.$filename.'.store';

    
  foreach my $i (0..($c->{entries}-1)) {
    for my $j (0..($c->{curves}-1)) {
      push(@{$p->{$name}->{value}->[$j]},0) ;
      }
    }
  
  if($p->{$name}->{storable}) {
    if (-e $storefile->{$name}) {
      $p->{$name}->{value} = lock_retrieve($storefile->{$name});
      }
    }


  if($p->{$name}->{output} == OUT_PNG) {
    $p->{$name}->{file} or die "No filename specified";
    plot_write($fh,"set term png size ".$p->{$name}->{sizex}.",".$p->{$name}->{sizey}." font \"monospace,8\"");
    plot_write($fh,"set out \"".$p->{$name}->{file}.($p->{$name}->{buffer}?"tmp":"").".png\"");
    }
  elsif($p->{$name}->{output} == OUT_SCREEN) {
    plot_write($fh,"set term x11 size ".$p->{$name}->{sizex}.",".$p->{$name}->{sizey});
    }
  else {
    die "Output mode not supported yet";
    }

  if  ($p->{$name}->{nokey}) {
    plot_write($fh,"unset key");
    }
  else {
    plot_write($fh,"set key left top");
    }


  plot_write($fh,"set xlabel \"".$p->{$name}->{xlabel}."\"") if $p->{$name}->{xlabel};
  plot_write($fh,"set ylabel \"".$p->{$name}->{ylabel}."\"") if $p->{$name}->{ylabel};

  if(defined $p->{$name}->{ymin} && defined $p->{$name}->{ymax}) {
    plot_write($fh,"set yrange [".$p->{$name}->{ymin}.":".$p->{$name}->{ymax}."]");
    }
  elsif(defined $p->{$name}->{ymax}) {
    plot_write($fh,"set yrange [:".$p->{$name}->{ymax}."]");
    }
  elsif(defined $p->{$name}->{ymin}) {
    plot_write($fh,"set yrange [".$p->{$name}->{ymin}.":]");
    }

  if(defined $p->{$name}->{xmin} && defined $p->{$name}->{xmax}) {
    plot_write($fh,"set xrange [".$p->{$name}->{xmin}.":".$p->{$name}->{xmax}."]");
    }
  elsif(defined $p->{$name}->{xmax}) {
    plot_write($fh,"set xrange [:".$p->{$name}->{xmax}."]");
    }
  elsif(defined $p->{$name}->{xmin}) {
    plot_write($fh,"set xrange [".$p->{$name}->{xmin}.":]");
    }

  if($p->{$name}->{addCmd} && $p->{$name}->{addCmd} ne "") {  
    plot_write($fh,$p->{$name}->{addCmd});
    }
    
  if($p->{$name}->{type} == TYPE_HISTORY) {
    if($p->{$name}->{fill}) {
      plot_write($fh,"set style fill solid 1.00");
      }
    else {
      plot_write($fh,"set style fill solid 0");
      }
    plot_write($fh,"set boxwidth 2 absolute");
    plot_write($fh,"set autoscale fix");
    plot_write($fh,"set xtics autofreq"); #$p->{$name}->{entries}
    plot_write($fh,"set grid");
#     plot_write($fh,"set style fill solid 1.0");
    plot_write($fh,"plot ",1);
    for(my $j=0; $j<$p->{$name}->{curves};$j++) {
      if($p->{$name}->{fill}) {
        plot_write($fh,"'-' using 1:2 with filledcurves x1 lt rgb \"".$p->{$name}->{colors}->[$j]."\" title \"".($p->{$name}->{titles}->[$j] || "$j")."\" ",1);
        }
      elsif($p->{$name}->{dots}) {
        plot_write($fh,"'-' using 1:2 with points pointsize 0.6 pointtype 2 lt rgb \"".$p->{$name}->{colors}->[$j]."\" title \"".($p->{$name}->{titles}->[$j] || "$j")."\" ",1);
        }
      else {
        plot_write($fh,"'-' using 1:2 with lines  lt rgb \"".$p->{$name}->{colors}->[$j]."\" title \"".($p->{$name}->{titles}->[$j] || "$j")."\" ",1);
        }
      plot_write($fh,', ',1) unless ($j+1==$p->{$name}->{curves});
      }
    plot_write($fh," ");
    }
  elsif($p->{$name}->{type} == TYPE_BARGRAPH) {
    plot_write($fh,"set style fill   solid 1.00 border -1");
    plot_write($fh,"set grid noxtics ytics");
    plot_write($fh,"set boxwidth ".($p->{$name}->{curvewidth}||4)." absolute");
    plot_write($fh,"set style histogram gap ".($p->{$name}->{bargap}||1));
    if(defined $p->{$name}->{bartitle} && scalar @{$p->{$name}->{bartitle}}) {
      plot_write($fh,"set xtics (",1);
      for(my $j=0; $j<scalar @{$p->{$name}->{bartitle}};$j++) {
        plot_write($fh,', ',1) if $j;
        plot_write($fh,"'".$p->{$name}->{bartitle}->[$j]."' $j ",1);
        }
      plot_write($fh,") offset 2.5,0 scale 0");
      }
    plot_write($fh,"set style histogram title offset character 0, 0, 0");
    plot_write($fh,"set style data histograms");
    plot_write($fh,"plot ",1);
    for(my $j=0; $j<$p->{$name}->{curves};$j++) {
      plot_write($fh,', ',1) if $j;
      plot_write($fh,"'-' lt rgb \"".$p->{$name}->{colors}->[$j]."\" title \"".($p->{$name}->{titles}->[$j] || "$j")."\" ",1);
      }
    plot_write($fh," ");
    }
  elsif($p->{$name}->{type} == TYPE_HEATMAP) {
    plot_write($fh,"set view map");
    plot_write($fh,"set palette rgbformulae 22,13,-31");
    if ($p->{$name}->{showvalues} == 0) {
      plot_write($fh,"splot '-' matrix with image");
      }
    else {
      plot_write($fh,"plot '-' matrix with image, '-' matrix using 1:2:(sprintf('%i', \$3)) with labels tc rgb \"#ffffff\" font ',10'");
      }
    }
  else {
    die "Plot type not supported";
    }

  }


sub PlotDraw {
  my($name) = @_;
  if($p->{$name}->{buffer} && -e $p->{$name}->{file}."tmp.png") {  
    rename $p->{$name}->{file}."tmp.png", $p->{$name}->{file}.".png";
    }
  if($p->{$name}->{run}>=1) {
    plot_write($p->{$name}->{fh},"set out \"".$p->{$name}->{file}.($p->{$name}->{buffer}?"tmp":"").".png\"");
    plot_write($p->{$name}->{fh},makeTimeString());
    plot_write($p->{$name}->{fh},"replot");
    }
    
  if($p->{$name}->{type} == TYPE_HISTORY) {  
    for(my $j=0; $j<$p->{$name}->{curves}; $j++) {
      for(my $i=0; $i< $p->{$name}->{entries}; $i++) {
        if ($p->{$name}->{countup}) {
          plot_write($p->{$name}->{fh},($i/$p->{$name}->{xscale})." ".$p->{$name}->{value}->[$j]->[$i]);
          }
        else {
          plot_write($p->{$name}->{fh},(($i-$p->{$name}->{entries})/$p->{$name}->{xscale})." ".$p->{$name}->{value}->[$j]->[$i]);
          }
        }
      plot_write($p->{$name}->{fh},"e");
      }  
    }
    
    
  if($p->{$name}->{type} == TYPE_BARGRAPH) { 
    for(my $j=0; $j<$p->{$name}->{curves}; $j++) {
      for(my $i=0; $i< $p->{$name}->{entries}; $i++) {
        plot_write($p->{$name}->{fh},' '.$p->{$name}->{value}->[$j]->[$i]);
        }
      plot_write($p->{$name}->{fh},"e");
      }
    }
      
      
  if($p->{$name}->{type} == TYPE_HEATMAP) {    
      if($p->{$name}->{showvalues}) {
        for(my $j=0; $j<$p->{$name}->{curves}; $j++) {
          for(my $i=0; $i< $p->{$name}->{entries}; $i++) {
            plot_write($p->{$name}->{fh},($p->{$name}->{value}->[$j]->[$i]||0)." ",1);
            }
          plot_write($p->{$name}->{fh}," ",0);
          }
        plot_write($p->{$name}->{fh},"e");      
        plot_write($p->{$name}->{fh},"e");     
        }
      for(my $j=0; $j<$p->{$name}->{curves}; $j++) {
        for(my $i=0; $i< $p->{$name}->{entries}; $i++) {
          plot_write($p->{$name}->{fh},($p->{$name}->{value}->[$j]->[$i]||0)." ",1);
          }
        plot_write($p->{$name}->{fh}," ",0);
        }
      plot_write($p->{$name}->{fh},"e");      
      plot_write($p->{$name}->{fh},"e");     

    }
    
    
  $p->{$name}->{run}++;
  
  
  if($p->{$name}->{storable}) {
    lock_store($p->{$name}->{value},$storefile->{$name});
    }
  }


sub PlotAdd {
  my($name,$value,$curve) = @_;
  $curve = 0 unless $curve;

  push(@{$p->{$name}->{value}->[$curve]},$value||0);
  shift(@{$p->{$name}->{value}->[$curve]});

  }

sub PlotFill {
  my($name,$value,$slot,$curve) = @_;
  $curve = 0 unless $curve;
  $p->{$name}->{value}->[$curve]->[$slot] = $value||0;
  }
  

1;
