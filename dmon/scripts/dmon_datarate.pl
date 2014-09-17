#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use lib "./code";
use lib "../tools";
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use Dmon;
use Data::Dumper;


my %config = Dmon::StartUp();

my $old;
my $value, my $longtext, my $status;


while(1) {
  my $errors = 0;
  my $max = 0; my $min = 1E9; my $sum = 0;
  my $r = trb_register_read(0xff7f,0x83b3);
  if (defined $old) {
    foreach my $c (keys %{$r}) {
      next unless defined $r->{$c};
      my $s = $r->{$c} - $old->{$c};
      if ($s < 0) {$s += 2**32;}
      if ($s > $max) {$max = $s;}
      if ($s < $min) {$min = $s;}
      $sum += $s;
      }

      
    my $title    = "Data Rate";
    $value = Dmon::SciNotation($sum)."b/s";
    
    my $longtext = "Total Data rate ".Dmon::SciNotation($sum)."b/s<br>Maximum per board: ".Dmon::SciNotation($max)."b/s";
    $status   = Dmon::OK;
    Dmon::WriteQALog($config{flog},"datarate",20,$status,$title,$value,$longtext);
    }
  $old = $r;  
  sleep 1;
  }
