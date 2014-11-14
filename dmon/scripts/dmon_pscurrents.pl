#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use lib "./code";
use lib "../tools";
use HADES::TrbNet;
use List::Util qw(min max);
use Time::HiRes qw(usleep);
use Dmon;
use HPlot;
use Data::Dumper;
use IO::Socket;


my %config = Dmon::StartUp();
my $script = $config{UserDirectory} . '/' . $config{PowerSupScript};

HPlot::PlotInit({
  name    => "PSCurrents",
  file    => Dmon::DMONDIR."PSCurrents",
  curves  => 20,
  entries => 300,
  type    => HPlot::TYPE_HISTORY,
  output  => HPlot::OUT_PNG,
  xlabel  => "Time [s]",
  ylabel  => "Current [A]",
  sizex   => 750,
  sizey   => 270,
  nokey   => 1,
  buffer  => 1
  });

my $str = Dmon::MakeTitle(10,6,"PSCurrents",0);
   $str .= qq@<img src="%ADDPNG PSCurrents.png%" type="image/png">@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("PSCurrents",$str);

while (1) {
  # get data from epics
  my $dataStr = `$script`;
  my @lines = split "\n", $dataStr;
  my %devices = ('hameg01', 0, 'hameg02', 0, 'hameg03', 0, 'tdklambda', 0);

  my $maximum = 0;
  my $total = 0;

  my @values;

  for my $line (@lines) {
    if ($line =~ /(hameg\d\d|tdklambda) CH (\d).*(\d+\.\d+) A.*(\d+\.\d+) V.*(ON|OFF)/) {
      my $dev = $1; my $chan = $2; my $curr = $3; my $volt = $4; my $state = $5;
      
      $curr = 0 if $state eq 'OFF';

      my $i = 0; #internal mapping 0: h0.c1, 1: h0.c2, .., 4: h1.c1, 5: h1.c2, .., 11: h3.c4, 12: tdklambda
      if ($dev eq 'tdklambda') {
        $i = 12;
      } else {
        $dev =~ /(\d\d)/;
        $i = 4 * ($1 - 1) + ($chan - 1);
        
        $maximum = $curr if $curr > $maximum;
        $total += $curr;
      }

      $devices{$dev} = 1;
      $values[$i] = $curr;
    }
  }

  for(my $i=0; $i < 12; $i++) {
    my $val = $values[$i];
    $val = '0' unless $val;
    HPlot::PlotAdd('PSCurrents',$val,$i);
  }


  my @devFound = ();
  my @devMissing = ();
  for my $dev (keys %devices) {
    push @devFound,   $dev if     $devices{$dev};
    push @devMissing, $dev unless $devices{$dev};
  }

  HPlot::PlotDraw('PSCurrents');

  my $title    = "PS Currents";
  my $value    = sprintf("%.2fA/%.2fA", $maximum, $total);
  my $longtext = "Maximum / Total current: " . $value . "<br />";
  $longtext .= 'TDK: ' . $values[12] . "A<br />";
  $longtext .= 'Sups found: ' . join(', ', @devFound) . "<br />" if @devFound;
  $longtext .= 'Sups missing: ' . join(', ', @devMissing) if @devMissing;

  my $status   = Dmon::OK;
  $status = Dmon::WARN if @devMissing;
  $status = Dmon::FATAL unless @devFound;
  

  Dmon::WriteQALog($config{flog},"pscurrents",30,$status,$title,$value,$longtext,'2-PSCurrents');

  sleep 1;
}





