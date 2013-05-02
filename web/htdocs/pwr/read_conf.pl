#!/usr/bin/perl -w
#print "Content-type: text/html\r\n\r\n";

use Cwd;

my $pwd = &Cwd::cwd();


open(LESEN,"htdocs/pwr/pwr.conf")
  or print "Fehler beim oeffnen von : $!\n";

while(defined(my $i = <LESEN>)) {

print $i;

	}



return true;
