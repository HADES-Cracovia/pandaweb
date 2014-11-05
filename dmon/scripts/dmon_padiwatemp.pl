#!/usr/bin/perl -w

use warnings;
use lib "./code";
use lib "../tools";
use HADES::TrbNet;
use Dmon;
use HPlot;
use Data::Dumper;

my %config = Dmon::StartUp();



sub sendcmd {
  my ($cmd,$board,$chain) = @_;
  my $c = [$cmd,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1<<$chain,0x10001];
  my $errcnt = 0;
  while(1){
    trb_register_write_mem($board,0xd400,0,$c,scalar @{$c});
    if (trb_strerror() ne "No Error") {
      sleep 1;
      if($errcnt >= 12) {
        die "SPI still blocked\n";
        }
      elsif($errcnt++ >= 10) {
        trb_register_read($board,0xd412);
        }
      }
    else {
      last;
      }
    } 
  return trb_register_read($board,0xd412);
  }
   

while(1) {
  my $max = 1; 
  my $min = 100;  
  my ($maxboard, $minboard);

  foreach my $b ($config{PadiwaTrbAdresses}) {
    my $r = sendcmd(0x10040000,$b,0);
    next unless defined $r;
    my $temp = (($r->{$b} & 0xFFF))/16;
    next if ($temp < 10 || $temp > 90);
    if ($max < $temp) {
      $max = $temp;
      $maxboard = $b;
      }
    elsif ($min > $temp) { 
      $min = $temp;
      $minboard = $b;
      }
    }
  
  my $title    = "Temperature";
  my $value    = sprintf("%.1f",$max);
  my $longtext = sprintf("Maximum: %.1f on board 0x%04x<br>Minimum: %.1f on board 0x%04x",$max,$maxboard,$min,$minboard);
  my $status   = Dmon::GetQAState('below',$max,(60,75,80));
  
  
  Dmon::WriteQALog($config{flog},"padiwatemp",30,$status,$title,$value,$longtext);

  sleep(15);
}
