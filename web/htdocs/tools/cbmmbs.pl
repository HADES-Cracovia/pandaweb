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

$page->{title} = "CBM MBS Receiver";
$page->{link}  = "../";

my @setup;
my $i = 0;

$setup[$i]->{name}    = "StatusAndControl";
$setup[$i]->{cmd}     = "CBMMBSRecv-0xffff-ControlAndStatus";
$setup[$i]->{period}  = -1;
$setup[$i]->{address} = 1;


xmlpage::initPage(\@setup,$page);

1;


