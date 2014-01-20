#!/usr/bin/perl
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  print "HTTP/1.0 200 OK\n";
  print header("text/html");
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

$page->{title} = "TDC Status & Control";
$page->{link}  = "../";

my @setup;
$setup[0]->{name}    = "Status";
$setup[0]->{cmd}     = "TDC-0xfe48-Status-rate";
$setup[0]->{refresh} = 1;
$setup[0]->{period}  = 10000;

$setup[1]->{name}    = "Control";
$setup[1]->{cmd}     = "TDC-0xfe48-Control";
$setup[1]->{refresh} = 1;
$setup[1]->{period}  = -1;


$setup[2]->{name}    = "Inputs";
$setup[2]->{cmd}     = "TDC-0xfe48-Channel-rate";
$setup[2]->{refresh} = 1;
$setup[2]->{period}  = 1000;

xmlpage::initPage(\@setup,$page);
 

 

1;


