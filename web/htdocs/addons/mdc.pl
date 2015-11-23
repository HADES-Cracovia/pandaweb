#!/usr/bin/perl
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  print "HTTP/1.0 200 OK\n";
  print "Content-type: text/html\r\n\r\n";
  }
else {
  use lib '..';
  use if (!($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i)), apacheEnv;
  print "Content-type: text/html\n\n";
  }

use CGI ':standard';
use XML::LibXML;
use POSIX;
use CGI::Carp qw(fatalsToBrowser);

use lib qw|../commands htdocs/commands|;
use xmlpage;

my $page;

$page->{title} = "MDCOEP";
$page->{link}  = "../";

my @setup;

push(@setup,({name      => "Status", 
              cmd       => "MDC-0xfffd-Status",
              period    => 1000,
              address   => 1}));

push(@setup,({name      => "Counters", 
              cmd       => "MDC-0xfffd-Counters",
              period    => 1000,
              address   => 1}));              
              
push(@setup,({name      => "Voltages", 
              cmd       => "MDC-0xfffd-Voltages",
              period    => 1000,
              address   => 1}));


xmlpage::initPage(\@setup,$page);
 

 

1;


