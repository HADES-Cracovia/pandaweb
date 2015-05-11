#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use Dmon;
use Data::Dumper;


my %config = Dmon::StartUp();

my $curr, my $old;


while(1) {
  my $errors = 0;
  my $sig1 = trb_register_read(0xffff,0x6);
  my $sig2 = trb_register_read(0xffff,0x7);
  my $diff;
  
  if(defined $old) {
    foreach my $b (keys $sig1) {
      $curr->[0]->{$b} = ($sig1->{$b} & 0xffff);
      $curr->[1]->{$b} = (($sig1->{$b}>>16) & 0xffff);
      $curr->[2]->{$b} = ($sig2->{$b} & 0xffff);
      $curr->[3]->{$b} = (($sig2->{$b}>>16) & 0xffff);
      
      $errors +=  $curr->[0]->{$b} - $old->[0]->{$b};
      $errors +=  $curr->[1]->{$b} - $old->[1]->{$b};
      $errors +=  $curr->[2]->{$b} - $old->[2]->{$b};
      $errors +=  $curr->[3]->{$b} - $old->[3]->{$b};
      
      }
    }
    
  
    
  my $longtext = "Number of errors with trigger reported: ".$errors;
  my $status = Dmon::GetQAState('below',$errors,(0,10,20));
  my $title  = "Trg Errors";
  Dmon::WriteQALog($config{flog},"trgerrors",10,$status,$title,$errors,$longtext);

  $old = $curr;
  sleep 1;
  }
