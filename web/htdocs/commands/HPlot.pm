package HPlot;
use POSIX qw/floor ceil strftime/;
# use Data::Dumper;
use warnings;
use strict;
use FileHandle;

my $p;

use constant {TYPE_HISTORY => 1};

use constant {OUT_PNG    => 1,
              OUT_SVG    => 2,  #n/a
              OUT_SCREEN => 3}; #n/a

my @color= ('#2222dd','#dd2222','#22dd22','#dd8822','#dd22dd','#22dddd');

sub plot_write {
  my ($file,$str,$no) = @_;
  return unless $str;
  if($no || 0) {
    print $file $str;
    }
  else {
    print $file $str."\n";
    }
  }


sub makeTimeString{
  return strftime("set label 100 \"%H:%M:%S\" at screen 0.02,0.02 left tc rgb \"#000044\" font \"monospace,8\"\n", localtime())
  }


sub PlotInit {
  my ($c) = @_;

  my $name      = $c->{name};

  my $fn = "gnuplot";
  my $fh = new FileHandle ("|$fn") or  die "error: no gnuplot";
  $fh->autoflush(1);



  $p->{$name} = $c;
  $p->{$name}->{fh} = $fh;
  $p->{$name}->{run} = 0;
  $p->{$name}->{sizex} = $p->{$name}->{sizex} || 600 ;
  $p->{$name}->{sizey} = $p->{$name}->{sizey} || 400 ;
  $p->{$name}->{file} = $p->{$name}->{file} || "dummy" ;
  $p->{$name}->{curves} = $p->{$name}->{curves} || 1 ;
  $p->{$name}->{xscale} = $p->{$name}->{xscale} || 1;
  $p->{$name}->{type}   or die "No plot type specified";
  $p->{$name}->{output} or die "No destination specified";

  @color = @{$p->{$name}->{colors}} if($p->{$name}->{colors});

  foreach my $i (0..($c->{entries}-1)) {
    for my $j (0..($c->{curves}-1)) {
      push(@{$p->{$name}->{value}->[$j]},0) ;
      }
    }

  if($p->{$name}->{output} == OUT_PNG) {
    $p->{$name}->{file} or die "No filename specified";
    plot_write($fh,"set term png size ".$p->{$name}->{sizex}.",".$p->{$name}->{sizey}." font \"monospace,8\"");
    plot_write($fh,"set out \"".$p->{$name}->{file}.".png\"");
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
        plot_write($fh,"'-' using 1:2 with filledcurves x1 lt rgb \"$color[$j]\" title \"".($p->{$name}->{titles}->[$j] || "$j")."\" ",1);
        }
      elsif($p->{$name}->{dots}) {
        plot_write($fh,"'-' using 1:2 with points pointsize 0.6 pointtype 2 lt rgb \"$color[$j]\" title \"".($p->{$name}->{titles}->[$j] || "$j")."\" ",1);
        }
      else {
        plot_write($fh,"'-' using 1:2 with lines  lt rgb \"$color[$j]\" title \"".($p->{$name}->{titles}->[$j] || "$j")."\" ",1);
        }
      plot_write($fh,', ',1) unless ($j+1==$p->{$name}->{curves});
      }
    plot_write($fh," ");
    }
  else {
    die "Plot type not supported";
    }

  }


sub PlotDraw {
  my($name) = @_;
  if($p->{$name}->{run}>=1) {
    plot_write($p->{$name}->{fh},"set out \"".$p->{$name}->{file}.".png\"");
    plot_write($p->{$name}->{fh},makeTimeString());
    plot_write($p->{$name}->{fh},"replot");
    }
  for(my $j=0; $j<$p->{$name}->{curves}; $j++) {
    for(my $i=0; $i< scalar @{$p->{$name}->{value}->[$j]}; $i++) {
      plot_write($p->{$name}->{fh},(($i-$p->{$name}->{entries})/$p->{$name}->{xscale})." ".$p->{$name}->{value}->[$j]->[$i]) unless $p->{$name}->{countup};
      plot_write($p->{$name}->{fh},($i/$p->{$name}->{xscale})." ".$p->{$name}->{value}->[$j]->[$i]) if $p->{$name}->{countup};
#       print $j." ".$i." ".$p->{$name}->{entries}." ".$p->{$name}->{xscale}." ".$p->{$name}->{value}->[$j]->[$i]."\n";
      }
    plot_write($p->{$name}->{fh},"e");
    }
  $p->{$name}->{run}++;
  }


sub PlotAdd {
  my($name,$value,$curve) = @_;
  $curve = 0 unless $curve;

  if($p->{$name}->{type} == TYPE_HISTORY) {
    push(@{$p->{$name}->{value}->[$curve]},$value||0);
    shift(@{$p->{$name}->{value}->[$curve]});
    }

  }


1;