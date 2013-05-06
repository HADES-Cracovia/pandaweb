#!/usr/bin/perl -w
use Cwd;
#print "Content-type: text/html\n\n";

my $pwd = &Cwd::cwd();


open(LESEN,"htdocs/pwr/pwr.conf")
  or die "Fehler beim oeffnen von : $!\n";

while(defined(my $i = <LESEN>)) {

	if( $i =~ /^PWRSPLY:([^:]+):([^:]+)/g ) {
		my $ser_dev=$1;
		my $dev_id=$2;
		
print <<EOF;
<p>
<iframe name="inlineframe" src="pwr.htm?device=$ser_dev&id=$dev_id" frameborder="0" scrolling="auto" width="800" height="340" ></iframe>
</p>
EOF
	}
}

#print "CWD: ".$pwd."<br>(for debug)\n";


return true;
