#!/usr/bin/perl
use HADES::TrbNet;
use Data::Dumper;
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  print "HTTP/1.0 200 OK\n";
  print header("text/html");
  }
else {
  use lib '..';
  use if (!($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i)), apacheEnv;
  print "Content-type: text/html\n\n";
  }




 if (!defined &trb_init_ports()) {
   die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
 }

my ($board,@addr) = split('-',$ENV{'QUERY_STRING'}); 
 
$board = hex($board);


my @hits;  

for(my $i=0;$i<scalar @addr;$i++) {
  $addr[$i] = hex($addr[$i]);
  $hits[$i] = trb_register_read($board,$addr[$i]);
  }
  
foreach my $b (sort keys %{$hits[0]}) {
  printf ("%04x",$b);
  for(my $i=0;$i<scalar @addr;$i++) {
    printf(" %d",$hits[$i]->{$b});
    }
  print "&";
  }
  
  
exit 1;