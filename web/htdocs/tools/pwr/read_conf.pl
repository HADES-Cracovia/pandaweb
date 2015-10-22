#!/usr/bin/perl -w
use Cwd;

if ($ENV{'SERVER_SOFTWARE'} =~ /HTTP-?i/i) {
  &htsponse(200, "OK");
  }
print "Content-type: text/html\n\n";


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
