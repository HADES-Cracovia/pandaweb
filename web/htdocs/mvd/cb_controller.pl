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

$page->{title} = "Converter Board Controller";
$page->{link}  = "../";

my @setup;
$setup[0]->{name}    = "CbCtrlReg";
$setup[0]->{cmd}     = "CbController-0xfe4d-CbCtrlReg";
$setup[0]->{period}  = 1000;
$setup[0]->{address} = 1;

$setup[1]->{name}    = "CbSpiStream";
$setup[1]->{cmd}     = "CbController-0xfe4d-CbSpiStream";
$setup[1]->{period}  = 1000;
$setup[1]->{address} = 1;

$setup[2]->{name}    = "CbUcReg";
$setup[2]->{cmd}     = "CbController-0xfe4d-CbUcReg";
$setup[2]->{period}  = 1000;
$setup[2]->{address} = 1;

# $setup[3]->{name}    = "UcRegs";
# $setup[3]->{cmd}     = "CbController-0xfe4d-CbUcRegs";
# $setup[3]->{period}  = 1000;
# $setup[3]->{address} = 1;

xmlpage::initPage(\@setup,$page);
 

 

1;



