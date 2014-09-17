#!/usr/bin/perl -w

use warnings;
use lib "./code";
use HADES::TrbNet;
use Dmon;
use Data::Dumper;

my %config = do $ARGV[0];
my $flog = Dmon::OpenQAFile();
trb_init_ports() or die trb_strerror();


while(1) {
  my $r = trb_register_read(0xffff,0);
  my $max = 0; 
  my $min = 100;  
  my ($maxboard, $minboard);
#   print Dumper $r;
  foreach my $b (keys %$r) {
    my $temp = (($r->{$b} & 0xFFF00000)>>20)/16;
    if ($max < $temp) {
      $max = $temp;
      $maxboard = $b;
      }
    elsif ($min > $temp) { 
      $min = $temp;
      $minboard = $b;
      }
    print STDERR $temp." ".$min."\n";
    }
  
  my $title    = "Temperature";
  my $value    = sprintf("%.1f",$max);
  my $longtext = sprintf("Maximum: %.1f on board 0x%04x<br>Minimum: %.1f on board 0x%04x",$max,$maxboard,$min,$minboard);
  my $status   = Dmon::GetQAState('below',$max,(60,75,80));
  
  
  Dmon::WriteQALog($flog,"temperature",20,$status,$title,$value,$longtext);

  sleep(10);
}
