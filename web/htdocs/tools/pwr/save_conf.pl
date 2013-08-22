#!/usr/bin/perl -w
print "Content-type: text/html\r\n\r\n";

my $envstring = $ENV{'QUERY_STRING'};
$envstring =~ s/%20/ /g;
$envstring =~ s/&/\n/g;
##$envstring =~ s/&/\n/g;


my $file = "pwr.conf";
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  $file = "htdocs/tools/pwr/".$file;
  }


open(SCHREIBEN,">$file")
  or print "Fehler beim oeffnen von : $!\n";

print SCHREIBEN $envstring;
close(SCHREIBEN);

print "saved!";


return true;
