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

$page->{title} = "Pulser AddOn";
$page->{link}  = "../";

my @setup;

push(@setup,({name      => "Control", 
              cmd       => "Pulser-0xfe61-GlobalConfig",
              period    => 1000,
              address   => 1}));

push(@setup,({name      => "PulserConfig", 
              cmd       => "Pulser-0xfe61-PulserConfig",
              period    => 10000,
              address   => 1}));
              
              
xmlpage::initPage(\@setup,$page);
 

 

1;


