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

$page->{title} = "Nxyter Register Advanced Mode";
$page->{link}  = "../";

my @setup;

$setup[0]->{name}    = "Rate_0";
$setup[0]->{cmd}     = "Nxyter-0x3800-RateHist-rate";
$setup[0]->{period}  = -1;
$setup[0]->{address} = 1;

$setup[1]->{name}    = "Rate_1";
$setup[1]->{cmd}     = "Nxyter-0x3801-RateHist-rate";
$setup[1]->{period}  = -1;
$setup[1]->{address} = 1;

$setup[2]->{name}    = "Pileup_0";
$setup[2]->{cmd}     = "Nxyter-0x3800-PileupHist-rate";
$setup[2]->{period}  = -1;
$setup[2]->{address} = 1;

$setup[3]->{name}    = "Pileup_1";
$setup[3]->{cmd}     = "Nxyter-0x3801-PileupHist-rate";
$setup[3]->{period}  = -1;
$setup[3]->{address} = 1;

$setup[4]->{name}    = "Ovfl_0";
$setup[4]->{cmd}     = "Nxyter-0x3800-OverFlowHist-rate";
$setup[4]->{period}  = -1;
$setup[4]->{address} = 1;

$setup[5]->{name}    = "Ovfl_1";
$setup[5]->{cmd}     = "Nxyter-0x3801-OverFlowHist-rate";
$setup[5]->{period}  = -1;
$setup[5]->{address} = 1;

$setup[6]->{name}    = "ADC_0";
$setup[6]->{cmd}     = "Nxyter-0x3800-ADCHist";
$setup[6]->{period}  = -1;
$setup[6]->{address} = 1;

$setup[7]->{name}    = "ADC_1";
$setup[7]->{cmd}     = "Nxyter-0x3801-ADCHist";
$setup[7]->{period}  = -1;
$setup[7]->{address} = 1;

$setup[8]->{name}    = "IToken_0";
$setup[8]->{cmd}     = "Nxyter-0x3800-I2CTokens";
$setup[8]->{period}  = -1;
$setup[8]->{address} = 1;

$setup[9]->{name}    = "IToken_1";
$setup[9]->{cmd}     = "Nxyter-0x3801-I2CTokens";
$setup[9]->{period}  = -1;
$setup[9]->{address} = 1;

xmlpage::initPage(\@setup,$page);

1;
