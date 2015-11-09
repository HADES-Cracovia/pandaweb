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

$page->{title} = "Input Monitor and Trigger Preparation";
$page->{link}  = "../";


my @setup;
$setup[0]->{name}    = "MonitorCtrl";
$setup[0]->{cmd}     = "InputMonitor-0xfe4e-MonitorRegs";
$setup[0]->{period}  = 1000;
$setup[0]->{address} = 1;
$setup[0]->{rate}    = 1;

$setup[1]->{name}    = "MonitorCounters";
$setup[1]->{cmd}     = "InputMonitor-0xfe4e-MonitorCounters";
$setup[1]->{period}  = 1000;
$setup[1]->{address} = 1;
$setup[1]->{rate}    = 1;

$setup[2]->{name}    = "Trigger";
$setup[2]->{cmd}     = "InputMonitor-0xfe4e-Trigger";
$setup[2]->{period}  = 1000;
$setup[2]->{address} = 1;
$setup[2]->{rate}    = 1;

$setup[3]->{name}    = "Trb3scMonitorCtrl";
$setup[3]->{cmd}     = "InputMonitorTrb3sc-0xfe60-MonitorRegs";
$setup[3]->{period}  = 1000;
$setup[3]->{address} = 1;
$setup[3]->{rate}    = 1;

$setup[4]->{name}    = "Trb3scMonitorCounters";
$setup[4]->{cmd}     = "InputMonitorTrb3sc-0xfe60-MonitorCounters";
$setup[4]->{period}  = 1000;
$setup[4]->{address} = 1;
$setup[4]->{rate}    = 1;

$setup[5]->{name}    = "Trb3scTrigger";
$setup[5]->{cmd}     = "InputMonitorTrb3sc-0xfe60-Trigger";
$setup[5]->{period}  = 1000;
$setup[5]->{address} = 1;
$setup[5]->{rate}    = 1;


xmlpage::initPage(\@setup,$page);
 

 

1;


