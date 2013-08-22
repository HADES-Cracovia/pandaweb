#!/usr/bin/perl -w
print "Content-type: text/html\r\n\r\n";

use Cwd;

my $pwd = &Cwd::cwd();

my $file = "pwr.conf";
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  $file = "htdocs/tools/pwr/".$file;
  }


open(LESEN,$file)
  or print "Fehler beim oeffnen von : $!\n";

while(defined(my $i = <LESEN>)) {

print $i;

	}



return true;
