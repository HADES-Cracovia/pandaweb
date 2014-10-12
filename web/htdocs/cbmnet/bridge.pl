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

$page->{title} = "CBMNet Bridge";
$page->{link}  = "../";

my @setup;
$setup[0]->{name}    = "Readout";
$setup[0]->{cmd}     = "CBMNetBridge-0xf3c0-Readout";
$setup[0]->{period}  = -1;
$setup[0]->{address} = 1;

$setup[1]->{name}    = "ReadoutDebug";
$setup[1]->{cmd}     = "CBMNetBridge-0xf3c0-ReadoutDebug";
$setup[1]->{period}  = -1;
$setup[1]->{address} = 1;

$setup[2]->{name}    = "SyncModule";
$setup[2]->{cmd}     = "CBMNetBridge-0xf3c0-SyncModule";
$setup[2]->{period}  = 1;
$setup[2]->{address} = 1;

xmlpage::initPage(\@setup,$page);

1;


