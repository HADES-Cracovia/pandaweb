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

$page->{title} = "Nxyter Register";
$page->{link}  = "../";

my @setup;

$setup[0]->{name}    = "Status";
$setup[0]->{cmd}     = "Nxyter-0xfe49-NXStatus&Nxyter-0xfe49-ADCStatus";
$setup[0]->{period}  = -1;
$setup[0]->{generic} = 1;

$setup[1]->{name}    = "DataReceiver";
$setup[1]->{cmd}     = "Nxyter-0xfe49-DataValidate&Nxyter-0xfe49-DataReceiver";
$setup[1]->{period}  = -1;
$setup[1]->{address} = 1;

$setup[2]->{name}    = "TrigValidate";
$setup[2]->{cmd}     = "Nxyter-0xfe49-TriggerValidate";
$setup[2]->{period}  = -1;
$setup[2]->{address} = 1;

$setup[3]->{name}    = "TriggerHandler";
$setup[3]->{cmd}     = "Nxyter-0xfe49-TriggerHandler&Nxyter-0xfe49-TriggerGenerator";
$setup[3]->{period}  = -1;
$setup[3]->{address} = 1;

$setup[4]->{name}    = "I2CRegister";
$setup[4]->{cmd}     = "Nxyter-0xfe49-NxyterI2C";
$setup[4]->{period}  = -1;
$setup[4]->{address} = 1;

$setup[5]->{name}    = "DAC_0";
$setup[5]->{cmd}     = "Nxyter-0x3800-NxyterDAC";
$setup[5]->{period}  = -1;
$setup[5]->{address} = 1;

$setup[6]->{name}    = "DAC_1";
$setup[6]->{cmd}     = "Nxyter-0x3801-NxyterDAC";
$setup[6]->{period}  = -1;
$setup[6]->{address} = 1;

xmlpage::initPage(\@setup,$page);

1;
