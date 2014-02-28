#!/usr/bin/perl
use HADES::TrbNet;
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  print "HTTP/1.0 200 OK\n";
  print "Content-type: text/html\r\n\r\n";
  }
else {
  use lib '..';
  use if (!($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i)), apacheEnv;
  print "Content-type: text/html\n\n";
  }


 if (!defined &trb_init_ports()) {
   die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
 }

my ($board,$addr,$mask,$value) = split('-',$ENV{'QUERY_STRING'}); 

if(!defined $board || !defined $addr || !defined $mask || !defined $value) {exit -1;}
$board = hex($board);
$addr = hex($addr);
$mask = hex($mask);
$value = hex($value);

print "$board $addr $mask $value\n";


trb_register_loadbit($board,$addr,$mask,$value);


  
exit 1;
