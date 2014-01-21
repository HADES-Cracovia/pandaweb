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

my ($board,$addr,$op,$value) = split('-',$ENV{'QUERY_STRING'}); 

if(!defined $board || !defined $addr || !defined $op || !defined $value) {exit -1;}
$board = hex($board);
$addr = hex($addr);
$value = hex($value);

print "$board $addr $value\n";


if($op eq "set") {
  trb_register_setbit($board,$addr,$value);
  }

if($op eq "clr") {
  trb_register_clearbit($board,$addr,$value);
  }


  
exit 1;
