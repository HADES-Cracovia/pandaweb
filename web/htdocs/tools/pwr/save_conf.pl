#!/usr/bin/perl -w


my $envstring = $ENV{'QUERY_STRING'};
$envstring =~ s/%20/ /g;
$envstring =~ s/&/\n/g;
##$envstring =~ s/&/\n/g;


open(SCHREIBEN,">htdocs/tools/pwr/pwr.conf")
  or print "Fehler beim oeffnen von : $!\n";

print SCHREIBEN $envstring;
close(SCHREIBEN);

print "saved!";


return true;
