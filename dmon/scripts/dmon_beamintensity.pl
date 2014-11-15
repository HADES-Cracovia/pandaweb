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


my %config = do $ARGV[0];
my $flog = Dmon::OpenQAFile();
trb_init_ports() or die trb_strerror();


my $value, my $longtext, my $status;

my $lasterrors = 0;
while(1) {
  my $errors = 0;
  foreach my $b (@{$config{TdcAddress}}) {
    my $r = trb_register_read($b,0xc100);
    foreach my $c (%{$r}) {
      if ($c & 0x10000) {$errors++;}
      }
    }
  my $title    = "Ref Polarity";
  
  if ($errors) { $value = $errors." errors"; }
  else         { $value = "OK";}
  
  my $longtext = "Polarity of the reference time signals on TDCs seems to be: ".$value;
  if($errors && $lasterrors) {  $status   = Dmon::GetQAState('below',$errors,(0,1,4));}
  else                       {  $status   = Dmon::OK;}
  Dmon::WriteQALog($flog,"reftime",20,$status,$title,$value,$longtext);
  $lasterrors = $errors;
  sleep 10;
  }
