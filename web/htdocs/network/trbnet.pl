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

$page->{title} = "TrbNet Status Register";
$page->{link}  = "../";

my @setup;
$setup[0]->{name}    = "StatusRegisters";
$setup[0]->{cmd}     = "TrbNet-0xffff-StatusRegisters";
$setup[0]->{period}  = 2000;

$setup[1]->{name}    = "BoardInfo";
$setup[1]->{cmd}     = "TrbNet-0xffff-BoardInformation";
$setup[1]->{period}  = -1;

$setup[2]->{name}    = "Readout";
$setup[2]->{cmd}     = "Readout-0xffff-Status";
$setup[2]->{period}  = -1;



xmlpage::initPage(\@setup,$page);
 

 

1;


