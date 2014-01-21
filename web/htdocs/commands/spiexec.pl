#!/usr/bin/perl
use HADES::TrbNet;
use Data::Dumper;
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  print "HTTP/1.0 200 OK\n";
  print "Content-type: text/html\r\n\r\n";
  }
else {
  use lib '..';
  use if (!($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i)), apacheEnv;
  print "Content-type: text/html\n\n";
  }



use HADES::TrbNet;
use Data::Dumper;

 if (!defined &trb_init_ports()) {
   die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
 }


my ($board,$addr,@values) = split('-',$ENV{'QUERY_STRING'}); 

if(!defined $board || !defined $addr || !defined $values[0]) {exit -1;}
$board = hex($board);
$addr = hex($addr);

for(my $x = 0; $x < scalar @values; $x++) {
  $values[$x] = hex($values[$x]);
  }


my $hits = trb_register_write_mem($board,$addr,0,\@values,scalar @values);

$hits = trb_register_read($board,0xd412);

  foreach my $b (sort keys %$hits) {
    printf ("%04x",$b);
    printf(" %d",($hits->{$b})&0xffff);
    print "&";
    }
  
  
exit 1;