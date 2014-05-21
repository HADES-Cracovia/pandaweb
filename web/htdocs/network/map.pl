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
use POSIX;
use CGI::Carp qw(fatalsToBrowser);

use lib qw|../commands htdocs/commands|;
use xmlpage;


###############################################################################  
##  Network Map
###############################################################################  
if($ENV{'QUERY_STRING'} =~ /getmap/) {
  print "Getting map";
  }
  
###############################################################################  
##  Main page
###############################################################################  
else {
  my $page;
  $page->{title} = "TrbNet Network Setup";
  $page->{link}  = "../";
  $page->{getscript} = "map.pl";

  my @setup;
  $setup[0]->{name}    = "NetworkMap";
  $setup[0]->{cmd}     = "getmap";
  $setup[0]->{period}  = -1;
  $setup[0]->{noaddress} = 0;
  $setup[0]->{generic}   = 0;

  xmlpage::initPage(\@setup,$page);
  } 

 

1;


