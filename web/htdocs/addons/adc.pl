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

$page->{title} = "ADC AddOn";
$page->{link}  = "../";

my @setup;

push(@setup,({name      => "Control", 
              cmd       => "ADC-0xfe4b-Control",
              period    => 1000,
              address   => 1}));

push(@setup,({name      => "Input", 
              cmd       => "ADC-0xfe4b-InputHandler&ADC-0xfe4b-InvalidWords",
              period    => 1000,
              address   => 1}));              
              
push(@setup,({name      => "BufferConfig", 
              cmd       => "ADC-0xfe4b-BufferConfig",
              period    => 1000,
              address   => 1}));

push(@setup,({name      => "ConfigProcessor", 
              cmd       => "ADC-0xfe4b-ProcessorConfig",
              period    => 1000,
              address   => 1}));

push(@setup,({name      => "StatusProcessor", 
              cmd       => "ADC-0xfe4b-ProcessorStatus",
              period    => 1000,
              address   => 1}));


push(@setup,({name      => "LastValues", 
              cmd       => "ADC-0xfe4b-LastValues",
              period    => 1000,
              address   => 1}));
              
push(@setup,({name      => "Baseline", 
              cmd       => "ADC-0xfe4b-Baseline",
              period    => 1000,
              address   => 1}));
              

xmlpage::initPage(\@setup,$page);
 

 

1;


