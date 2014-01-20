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

$page->{title} = "Generic Register Display";
$page->{link}  = "../";


my @setup;
$setup[0]->{name}    = "AnyReg";
$setup[0]->{cmd}     = "TrbNet-0xffff-CompileTime";
$setup[0]->{period}  = -1;
$setup[0]->{generic} = 1;
$setup[0]->{rate}    = 1;


xmlpage::initPage(\@setup,$page);
 

 

1;


