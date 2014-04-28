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

$setup[0]->{name}    = "R_0";
$setup[0]->{cmd}     = "Nxyter-0x3800-RateHist-rate";
$setup[0]->{period}  = -1;
$setup[0]->{address} = 1;

$setup[1]->{name}    = "R_1";
$setup[1]->{cmd}     = "Nxyter-0x3801-RateHist-rate";
$setup[1]->{period}  = -1;
$setup[1]->{address} = 1;

$setup[2]->{name}    = "R_2";
$setup[2]->{cmd}     = "Nxyter-0x3810-RateHist-rate";
$setup[2]->{period}  = -1;
$setup[2]->{address} = 1;

$setup[3]->{name}    = "R_3";
$setup[3]->{cmd}     = "Nxyter-0x3811-RateHist-rate";
$setup[3]->{period}  = -1;
$setup[3]->{address} = 1;

$setup[4]->{name}    = "P_0";
$setup[4]->{cmd}     = "Nxyter-0x3800-PileupHist-rate";
$setup[4]->{period}  = -1;
$setup[4]->{address} = 1;

$setup[5]->{name}    = "P_1";
$setup[5]->{cmd}     = "Nxyter-0x3801-PileupHist-rate";
$setup[5]->{period}  = -1;
$setup[5]->{address} = 1;

$setup[6]->{name}    = "P_2";
$setup[6]->{cmd}     = "Nxyter-0x3810-PileupHist-rate";
$setup[6]->{period}  = -1;
$setup[6]->{address} = 1;

$setup[7]->{name}    = "P_3";
$setup[7]->{cmd}     = "Nxyter-0x3811-PileupHist-rate";
$setup[7]->{period}  = -1;
$setup[7]->{address} = 1;

$setup[8]->{name}    = "O_0";
$setup[8]->{cmd}     = "Nxyter-0x3800-OverFlowHist-rate";
$setup[8]->{period}  = -1;
$setup[8]->{address} = 1;

$setup[9]->{name}    = "O_1";
$setup[9]->{cmd}     = "Nxyter-0x3801-OverFlowHist-rate";
$setup[9]->{period}  = -1;
$setup[9]->{address} = 1;

$setup[10]->{name}    = "O_2";
$setup[10]->{cmd}     = "Nxyter-0x3810-OverFlowHist-rate";
$setup[10]->{period}  = -1;
$setup[10]->{address} = 1;

$setup[11]->{name}    = "O_3";
$setup[11]->{cmd}     = "Nxyter-0x3811-OverFlowHist-rate";
$setup[11]->{period}  = -1;
$setup[11]->{address} = 1;

$setup[12]->{name}    = "A_0";
$setup[12]->{cmd}     = "Nxyter-0x3800-ADCHist";
$setup[12]->{period}  = -1;
$setup[12]->{address} = 1;

$setup[13]->{name}    = "A_1";
$setup[13]->{cmd}     = "Nxyter-0x3801-ADCHist";
$setup[13]->{period}  = -1;
$setup[13]->{address} = 1;

$setup[14]->{name}    = "A_2";
$setup[14]->{cmd}     = "Nxyter-0x3810-ADCHist";
$setup[14]->{period}  = -1;
$setup[14]->{address} = 1;

$setup[15]->{name}    = "A_3";
$setup[15]->{cmd}     = "Nxyter-0x3811-ADCHist";
$setup[15]->{period}  = -1;
$setup[15]->{address} = 1;

$setup[16]->{name}    = "IT_0";
$setup[16]->{cmd}     = "Nxyter-0x3800-I2CTokens";
$setup[16]->{period}  = -1;
$setup[16]->{address} = 1;

$setup[17]->{name}    = "IT_1";
$setup[17]->{cmd}     = "Nxyter-0x3801-I2CTokens";
$setup[17]->{period}  = -1;
$setup[17]->{address} = 1;

$setup[18]->{name}    = "IT_2";
$setup[18]->{cmd}     = "Nxyter-0x3810-I2CTokens";
$setup[18]->{period}  = -1;
$setup[18]->{address} = 1;

$setup[19]->{name}    = "IT_3";
$setup[19]->{cmd}     = "Nxyter-0x3811-I2CTokens";
$setup[19]->{period}  = -1;
$setup[19]->{address} = 1;

xmlpage::initPage(\@setup,$page);

1;
