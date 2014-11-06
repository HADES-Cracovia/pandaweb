#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use lib "./code";
use lib "../tools";
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use Dmon;
use Net::Ping;

my %config = Dmon::StartUp();


my $ping = Net::Ping->new();
while(1) {
  my $found = 0;
  my $notavail = 0;
  my $list = "";
  my $total = scalar @{$config{TrbIP}};
  foreach my $p (@{$config{TrbIP}}) {
    my $r = $ping->ping($p,1);
    $found    += $r || 0;
    $notavail += 1-($r||0);
    $list .= " $p" unless $r;
    }

  my $title    = "Ping";
  my $value    = sprintf("%i / %i",$found,$total);
  my $longtext = sprintf("Total in list: %i. Boards reacting: %i. Boards not found: %s.",$total,$found,$list);
  my $status   = Dmon::GetQAState('above',$found,($total,$total,$total-1));
  Dmon::WriteQALog($config{flog},"ping",30,$status,$title,$value,$longtext,"");
  
  sleep(15);  
  }