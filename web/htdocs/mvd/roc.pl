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

$page->{title} = "MVD Read-out Controller Register";
$page->{link}  = "../";

my @setup;
$setup[0]->{name}    = "RocStatus";
$setup[0]->{cmd}     = "Mvd-0xfe4d-RocStatus";
$setup[0]->{period}  = 1000;
$setup[0]->{address} = 1;

$setup[1]->{name}    = "RocStatistics";
$setup[1]->{cmd}     = "Mvd-0xfe4d-RocStatistics";
$setup[1]->{period}  = 1000;
$setup[1]->{address} = 1;

$setup[2]->{name}    = "ClusterFinder";
$setup[2]->{cmd}     = "Mvd-0xfe4d-ClusterFinder";
$setup[2]->{period}  = 1000;
$setup[2]->{address} = 1;

$setup[3]->{name}    = "RocControl";
$setup[3]->{cmd}     = "Mvd-0xfe4d-RocControl";
$setup[3]->{period}  = 10000;
$setup[3]->{address} = 1;

xmlpage::initPage(\@setup,$page);
 

 

1;


