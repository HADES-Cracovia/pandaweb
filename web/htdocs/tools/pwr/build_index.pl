#!/usr/bin/perl -w
use Cwd;
#print "Content-type: text/html\n\n";

my $pwd = &Cwd::cwd();


open(LESEN,"htdocs/tools/pwr/pwr.conf")
  or die "Fehler beim oeffnen von : $!\n";

while(defined(my $i = <LESEN>)) {

	if( $i =~ /^PWRSPLY:([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)/g ) {
		my $ser_dev=$1;
    my $speed=$2;
		my $dev_id=$3;
		my $type=$4;
		my $channels=$5;

if($type eq "PSP") {
print <<EOF;
<p>
<iframe name="inlineframe" src="pwr.htm?device=$ser_dev&id=$dev_id&speed=$speed" frameborder="0" scrolling="auto" width="800" height="340" ></iframe>
</p>
EOF
}

if($type =~ /HMP/) {
print <<EOF;
<p>
<iframe name="inlineframe" src="pwr_hmp.htm?device=$ser_dev&id=$dev_id&type=$type&channels=$channels&speed=$speed" frameborder="0" scrolling="auto" width="800" height="340" ></iframe>
</p>
EOF
}



	}
}



#print "CWD: ".$pwd."<br>(for debug)\n";


return true;
