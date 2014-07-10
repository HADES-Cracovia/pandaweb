#!/usr/bin/perl

use warnings;
use lib "./code";
use Dmon;
use Data::Dumper;

my %config;

if(defined $ARGV[0]) {
  print "Loading settings from $ARGV[0]\n";
  %config = do $ARGV[0];
  }
else {
  die "Configuration file needed\n";
  }
  
# $config{activeScripts} = [['time'],['-']];  
  
# print Dumper $config{activeScripts};

# exit;

print "  <Dmon>     Creating Files and Links...\n";

system("mkdir -p /dev/shm/dmon");
system("mkdir -p /tmp/dmonlogs");
system("ln -fs /dev/shm/dmon ../web/htdocs/dmon");
# system("ln -fs /tmp/dmonlogs /dev/shm/dmon/logs");
system("ln -fs `pwd`/code /dev/shm/dmon/");
system("ln -fs `pwd`/code/index.pl /dev/shm/dmon/index.pl");

print "  <Dmon>     Starting scripts...\n";

print "Starting QA\n";
system("scripts/dmon_qa.pl $ARGV[0] 2>>/tmp/dmonlogs/qa_log.txt &");

my $r, my @l;
foreach my $row (@{$config{activeScripts}}) {
  foreach my $script (@$row) {
    next if $script eq '-';
    $r=fork(); 
    push(@l, $r); 
    if($r == 0) { 
      print "\t\tRunning ".$script."\n"; 
      system("killall dmon_$script.pl");
      system("scripts/dmon_$script.pl $ARGV[0] 2>>/tmp/dmonlogs/".$script."_log.txt"); 
      exit;
      } 
    }
  }
END: {if($r!=0 and eof()) {foreach (@l) {wait}}}


