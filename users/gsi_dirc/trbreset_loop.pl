#!/usr/bin/perl

use strict; 
use warnings;

### Change THIS!
my $required_endpoints = 25;


my $max_counter = 10;
my $counter = 0;
my $number = 0;


while (($number != $required_endpoints) || ($counter > $max_counter)) {
    my $c; my $res;

    $counter++;
    $c= "trbcmd reset";
    $res = qx($c);

    $c = "trbcmd i 0xffff | wc -l";
    $res = qx($c),
    print "- number of trb endpoints in the system: $res";
    ($number) = $res =~ /(\d+)/;
    print "number of enpoints smaller than $required_endpoints, so try next reset!\n" if ($number <$required_endpoints);
    #exit;
}
