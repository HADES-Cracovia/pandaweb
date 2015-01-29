#!/usr/bin/perl
  use Data::Dumper;

use CGI::Carp qw(warningsToBrowser fatalsToBrowser); 
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  print "HTTP/1.0 200 OK\n";
  print "Content-type: text/html\r\n\r\n";
  }
else {
  print "Content-type: text/html\n\n";
  use if (!($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i)), apacheEnv;
  }

use CGI qw/:standard/;

my $q = lc($ENV{'QUERY_STRING'} || '');
(my $led, my $col) = $q =~ /-([fb])-([0-9a-f]{6})-/;

return 0 if (!$led || !$col);

open FH, ">", "/dev/ttyUSB0";
print FH "AT#" . ($led eq 'f' ? '1' : '0') . $col;
close FH;

return 1;