#!/usr/bin/perl -w
#print "Content-type: text/html\n\n";


use strict;
use warnings;
use URI::Escape;
use Data::Dumper;

my $executable = "./vxi11_cmd";
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  $executable = "htdocs/tools/vxi/vxi11_cmd";
  }

my $envstring = $ENV{'QUERY_STRING'};
$envstring =~ s/%20/ /g;

my @new_command = split('&',$envstring); 
my $dev_ip = shift(@new_command);
my $cmds   = shift(@new_command);


$cmds = uri_unescape($cmds);
my @new_cmds = split('\n',$cmds); 

foreach my $c (@new_cmds) {
  chomp $c;
  my $call = "$executable $dev_ip $c 2>&1";
  my @o = qx($call);
  if($c =~ /\?/) {
    foreach my $l (@o) {
      print $l;
      }
    }
  print "---\n";
  }
  
  
  
return 1;