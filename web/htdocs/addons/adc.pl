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

$page->{title} = "ADC AddOn";
$page->{link}  = "../";

my @setup;
$setup[0]->{name}    = "BufferConfig";
$setup[0]->{cmd}     = "ADC-0xfe4b-BufferConfig";
$setup[0]->{period}  = 5000;
$setup[0]->{address} = 1;

$setup[1]->{name}    = "ProcessingConfig";
$setup[1]->{cmd}     = "ADC-0xfe4b-ProcessingConfig";
$setup[1]->{period}  = 5000;
$setup[1]->{address} = 1;


xmlpage::initPage(\@setup,$page);
 

 

1;


