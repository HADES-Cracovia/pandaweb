#!/usr/bin/env perl
use warnings;
use strict;
use POSIX qw(strftime);
use Data::Dumper;
use HADES::TrbNet;
use Term::ANSIColor;

trb_init_ports() or die trb_strerror();

local $| = 1;

print "usage: [startOff] [stopOff] [stepWidth]\n";

# my $startOff = $ARGV[0] || 1000;
# my $stopOff = $ARGV[1] || 0;
# my $step = sprintf("%d", $ARGV[2] || (($stopOff-$startOff) / 60.0));

my $recordTime = 300; # s 
my $minHodoHits = 60000; # hits to be registered by 

# die "Need negative step" if ($startOff >= $stopOff and $step >= 0);
# die "Need positive step" if ($startOff <= $stopOff and $step <= 0);

my $evtBldDir = "/mnt/data/tmp/";
my $swpDir = "/mnt/data/offset_sweep/ringb/";

#print "Scan from offset $startOff to $stopOff in steps of $step\n";

my $i = 0;
#for (my $offset = $startOff; $step * $offset <= $stopOff * $step; $offset += $step) {

for my $offset(0, 50, 100, 150, 200, 400, 750, 1000, 1500, 2000) {
#for my $offset(400, 750, 1000, 1500, 2000) {
  print color 'bold red';
  print strftime("%Y-%m-%d %H:%M:%S",localtime()) . " Iteration " . (++$i) . " Offset $offset <-------------------------------\n ";
  print color 'reset';
  
  my $pad = `../../tools/padiwa.pl 0xfe4c 0 uid`;
  my @padLines = split "\n", $pad;
  die "expect 66 pads" unless (scalar @padLines) == 66;
  die "unexpected ids:\n$pad" unless scalar grep(/0x..0000........28/, @padLines) == 66;
  
  print "All Pad seem to be there\n";

  system("trbcmd setbit 0x7005 0xa00c 0x80000000"); # full stop of cts
  system("./write_thresholds.pl --offset=$offset thresh/current_thresholds.thr");
  
  sleep 2;
#  system("trbcmd w 0x7005 0xa14e 9999"); # pulser 0
#  system("trbcmd w 0x7005 0xa101 1"); # select only pulser
  
  system("trbcmd clearbit 0x7005 0xa00c 0x80000000"); # engage cts

  sleep 1;
  
  print "Padiwas updated. Start recording\n";
  
  my @filesBefore = glob("$evtBldDir/*.hld");
  
  system("./evtbuilder_start.sh &");
    
  my $startHodo = trb_register_read(0x0110, 0xc005)->{0x0110} & 0x00ffffff ;
  my $remain = $minHodoHits;
  my $k = $recordTime;
  while ($k > 0 or $remain > 0) {
    sleep 1;
    
    my $currentHodo = trb_register_read(0x0110, 0xc005)->{0x0110}  & 0x00ffffff;
    my $hodoDiff = $currentHodo - $startHodo;
    #$hodoDiff += 0x100000000 if ($hodoDiff < 0);
    $remain = $minHodoHits - $hodoDiff;

    $k-- if $k > 0;
    
    printf "Wait for % 3ds and % 5d hodo hits (start cnt: %08x, current cnt: %08x, diff: %d) \n", $k, $remain, $startHodo, $currentHodo, $hodoDiff;
  }
  
  my $pids = `cat /mnt/data/tmp/evtbuild/.*.pid`;
  $pids =~ s/\s+/ /g;
  system("kill $pids");
  sleep 1;

  my %filesBefore = map {$_ => 1} @filesBefore;
  my @filesAfter = glob("$evtBldDir/*.hld");
  my @diff  = grep {not $filesBefore{$_}} @filesAfter;
  
  printf "Found %d files\n", scalar @diff;
  
  my $newDir = sprintf "$swpDir/offset%05d", $offset;
  system "mkdir -p $newDir";
  for my $fn (@diff) {
    $fn =~ /\/(te\d+\.hld)/;
    my $bfn = $1;
    print "Got file $bfn\n";
    system "mv $fn $newDir/$bfn";
  }
}
