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
my $i = 0;

$setup[$i]->{name}    = "Readout";
$setup[$i]->{cmd}     = "CBMNetBridge-0xf3c0-Readout";
$setup[$i]->{period}  = -1;
$setup[$i]->{address} = 1;

$i++;
$setup[$i]->{name}    = "ReadoutDebug";
$setup[$i]->{cmd}     = "CBMNetBridge-0xf3c0-ReadoutDebug";
$setup[$i]->{period}  = -1;
$setup[$i]->{address} = 1;

$i++;
$setup[$i]->{name}    = "SyncModule";
$setup[$i]->{cmd}     = "CBMNetBridge-0xf3c0-SyncModule";
$setup[$i]->{period}  = 1;
$setup[$i]->{address} = 1;

$i++;
$setup[$i]->{name}    = "LinkDebug";
$setup[$i]->{cmd}     = "CBMNetBridge-0xf3c0-LinkDebug";
$setup[$i]->{period}  = 1;
$setup[$i]->{address} = 1;

$i++;
$setup[$i]->{name}    = "TrbNetPatternGen";
$setup[$i]->{cmd}     = "CBMNetBridge-0x8001-TrbNetPatternGen";
$setup[$i]->{period}  = 1;
$setup[$i]->{address} = 1;


xmlpage::initPage(\@setup,$page);

1;


