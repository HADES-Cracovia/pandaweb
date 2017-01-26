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
  or die "Fehler beim oeffnen von : $!\n";

while(defined(my $i = <LESEN>)) {

	if( $i =~ /^PWRSPLY:([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)/g ) {
	  my @arr = split(':',$i);
	  shift @arr;
		my $ser_dev  = shift @arr;
    my $speed    = shift @arr;
		my $dev_id   = shift @arr;
		my $type     = shift @arr;
		my $channels = shift @arr;
		my $names = join(':',@arr);

if($type eq "PSP") {
print <<EOF;
<p>
<iframe name="inlineframe" src="pwr.htm?device=$ser_dev&id=$dev_id&speed=$speed&type=$type" frameborder="0" scrolling="auto" width="800" height="340" ></iframe>
</p>
EOF
}

if($type =~ /HMP/ or $type =~ /HMC/ or $type =~ /PST/) {
print <<EOF;
<p>
<iframe name="inlineframe" src="pwr_hmp.htm?device=$ser_dev&id=$dev_id&type=$type&channels=$channels&speed=$speed&names=$names" frameborder="0" scrolling="auto" width="800" height="340" ></iframe>
</p>
EOF
}

if($type =~ /PWRSW/) {
print <<EOF;
<p>
<iframe name="inlineframe" src="pwr_switch.htm?device=$ser_dev&id=$dev_id&type=$type&channels=$channels&speed=$speed&names=$names" frameborder="0" scrolling="auto" width="800" height="340" ></iframe>
</p>
EOF
}


	}
}



#print "CWD: ".$pwd."<br>(for debug)\n";


return true;
