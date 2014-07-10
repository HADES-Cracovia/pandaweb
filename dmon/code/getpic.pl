#!/usr/bin/perl
use warnings;
use strict;
use Data::Dumper;
use File::Copy;
my @args = split('-',$ENV{'QUERY_STRING'});

unless($args[0] =~ m/\w+/) {exit;}
if($args[0] =~ m/\./) {exit;}



print "Cache-Control: no-cache, must-revalidate, max-age=1\r\n";
print "Expires: Thu, 01 Dec 1994 16:00:00 GMT\r\n";
print "Content-type: image/png\r\n\r\n";

system ("cat /dev/shm/files/".$args[0].".png");
			
		
