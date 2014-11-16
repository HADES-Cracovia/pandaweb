#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use Dmon;
use Data::Dumper;


my %config = Dmon::StartUp();

my $old, my $value;
my $lasterrors = 0;
while(1) {
  my $errors = 0;
  my $sig = trb_register_read($config{BeamTRB},$config{BeamChan});
  my $title    = "Last Spill";
  
  my $curr = $sig->{$config{BeamTRB}} & 0xffffff;

  if($curr - $old > $config{SpillThreshold}) {
    $value += $curr - $old||0;
    }
  else {
    if ($value > 0) {
      my $longtext = "Number of signals in last spill: ".$value;
      my $status = Dmon::OK;
      Dmon::WriteQALog($config{flog},"beamintensity",60,$status,$title,$value,$longtext);
      $value = 0;
      }
    }      



  $old = $curr;
  sleep 1;
  }
